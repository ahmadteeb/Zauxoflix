import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/backend/remote_models.dart';
import '../../data/backend/remote_repository.dart';

class RemoteControlArgs {
  const RemoteControlArgs(this.device);

  final RemoteDevice device;
}

/// Phone-as-remote for playback running on another of the account's devices.
/// Renders the target's last remote-status snapshot (extrapolating the
/// position between the ~5s reports) and sends transport commands back
/// through the backend relay.
class RemoteControlScreen extends ConsumerStatefulWidget {
  const RemoteControlScreen({super.key, required this.args});

  final RemoteControlArgs args;

  @override
  ConsumerState<RemoteControlScreen> createState() =>
      _RemoteControlScreenState();
}

class _RemoteControlScreenState extends ConsumerState<RemoteControlScreen> {
  Timer? _ticker;
  double? _dragValue;

  RemoteDevice get _device => widget.args.device;

  @override
  void initState() {
    super.initState();
    // A lingering snapshot from an earlier session must not flash old content.
    // Post-frame: this screen is pushed during a build, and notifying the
    // provider's listeners mid-build throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(remoteStatusProvider.notifier).clear();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  RemoteStatus? get _status {
    final status = ref.watch(remoteStatusProvider);
    return status?.deviceId == _device.deviceId ? status : null;
  }

  int _positionSec(RemoteStatus status) {
    var position = status.positionSec;
    if (status.state == 'playing' && status.receivedAt != null) {
      position += DateTime.now().difference(status.receivedAt!).inSeconds;
    }
    return status.durationSec > 0
        ? position.clamp(0, status.durationSec)
        : position;
  }

  Future<void> _send(
    Future<void> Function(RemoteRepository repo) command,
  ) async {
    try {
      await command(ref.read(remoteRepositoryProvider));
    } on RemoteException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _stop() {
    unawaited(_send((repo) => repo.transport(_device.deviceId, 'stop')));
    Navigator.of(context).pop();
  }

  static String _fmt(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'On ${_device.displayName}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  child: status == null || status.state == 'loading'
                      ? _Waiting(deviceName: _device.displayName)
                      : status.state == 'idle'
                      ? _Idle(deviceName: _device.displayName)
                      : _controls(status),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls(RemoteStatus status) {
    final playing = status.state == 'playing';
    final seekable = !status.live && status.durationSec > 0;
    final positionSec = _dragValue?.round() ?? _positionSec(status);
    return Column(
      children: [
        const Spacer(),
        Icon(
          _device.isTv ? Icons.tv_rounded : Icons.cast_connected_rounded,
          size: 72,
          color: AppColors.primary,
        ),
        const SizedBox(height: 28),
        Text(
          status.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        if (status.subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            status.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
        const Spacer(),
        if (seekable)
          Row(
            children: [
              Text(
                _fmt(positionSec),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    activeTrackColor: AppColors.primary,
                    thumbColor: AppColors.primary,
                    inactiveTrackColor: Colors.white24,
                  ),
                  child: Slider(
                    value: positionSec.clamp(0, status.durationSec).toDouble(),
                    max: status.durationSec.toDouble(),
                    onChanged: (v) => setState(() => _dragValue = v),
                    onChangeEnd: (v) {
                      setState(() => _dragValue = null);
                      unawaited(
                        _send((repo) => repo.seek(_device.deviceId, v.round())),
                      );
                    },
                  ),
                ),
              ),
              Text(
                _fmt(status.durationSec),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              onPressed: status.hasPrev
                  ? () => _send(
                      (repo) => repo.transport(_device.deviceId, 'prev'),
                    )
                  : null,
              icon: const Icon(Icons.skip_previous_rounded, size: 36),
            ),
            if (seekable)
              IconButton(
                onPressed: () => _send(
                  (repo) => repo.seek(
                    _device.deviceId,
                    (_positionSec(status) - 10).clamp(0, status.durationSec),
                  ),
                ),
                tooltip: 'Rewind 10 seconds',
                icon: const Icon(Icons.replay_10_rounded, size: 32),
              ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () => _send(
                (repo) => repo.transport(
                  _device.deviceId,
                  playing ? 'pause' : 'resume',
                ),
              ),
              tooltip: playing ? 'Pause' : 'Resume',
              iconSize: 68,
              color: Colors.white,
              icon: Icon(
                playing
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
              ),
            ),
            const SizedBox(width: 10),
            if (seekable)
              IconButton(
                onPressed: () => _send(
                  (repo) => repo.seek(
                    _device.deviceId,
                    (_positionSec(status) + 30).clamp(0, status.durationSec),
                  ),
                ),
                tooltip: 'Forward 30 seconds',
                icon: const Icon(Icons.forward_30_rounded, size: 32),
              ),
            IconButton(
              onPressed: status.hasNext
                  ? () => _send(
                      (repo) => repo.transport(_device.deviceId, 'next'),
                    )
                  : null,
              icon: const Icon(Icons.skip_next_rounded, size: 36),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _stop,
          icon: const Icon(Icons.stop_rounded, size: 20),
          label: const Text('Stop playback'),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 18),
          Text(
            'Starting on $deviceName…',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.tv_off_rounded,
            size: 52,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing is playing on $deviceName.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
