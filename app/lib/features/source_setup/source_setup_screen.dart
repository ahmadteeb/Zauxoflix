import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/xtream/xtream_api.dart';

class SourceSetupScreen extends ConsumerStatefulWidget {
  const SourceSetupScreen({super.key});

  @override
  ConsumerState<SourceSetupScreen> createState() => _SourceSetupScreenState();
}

class _SourceSetupScreenState extends ConsumerState<SourceSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _server = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _playlistUrl = TextEditingController();
  final _epgUrl = TextEditingController();

  SourceType _type = SourceType.xtream;
  bool _connecting = false;
  String? _error;

  @override
  void dispose() {
    _server.dispose();
    _username.dispose();
    _password.dispose();
    _playlistUrl.dispose();
    _epgUrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      final id = switch (_type) {
        SourceType.xtream => await _connectXtream(),
        SourceType.m3u => await _connectM3u(),
      };

      // Fire the catalog sync; rails fill in live as tables are populated.
      final db = ref.read(databaseProvider);
      final source = await (db.select(
        db.sources,
      )..where((s) => s.id.equals(id))).getSingle();
      // ignore: unawaited_futures
      ref.read(syncControllerProvider.notifier).syncSource(source);
      if (mounted) context.go('/home');
    } on XtreamApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  /// Replaces any existing local source with the freshly validated one. The
  /// account was already saved to the backend, so every path into the catalog
  /// agrees on the same creds.
  Future<int> _adoptSource(SourcesCompanion companion) async {
    final db = ref.read(databaseProvider);
    return db.transaction(() async {
      final existing = await db.watchActiveSource().first;
      if (existing != null &&
          existing.sourceType == companion.sourceType.value &&
          existing.serverUrl == companion.serverUrl.value &&
          existing.username == companion.username.value &&
          existing.password == companion.password.value &&
          existing.epgUrl == companion.epgUrl.value) {
        return existing.id;
      }
      if (existing != null) await db.deleteSource(existing.id);
      return db.insertSource(companion);
    });
  }

  Future<int> _connectXtream() async {
    final credentials = XtreamCredentials(
      serverUrl: _server.text,
      username: _username.text.trim(),
      password: _password.text.trim(),
    );

    final info = await XtreamApi(credentials).authenticate();
    if (!info.authenticated) {
      throw XtreamApiException(
        'Login refused (status: ${info.status}). Check the credentials.',
      );
    }

    // Vault the account on the backend first so it roams to other devices;
    // a locked deployment rejects here before anything changes locally.
    await _saveToBackend(
      () => ref
          .read(provisionRepositoryProvider)
          .saveXtreamSource(
            serverUrl: credentials.serverUrl,
            username: credentials.username,
            password: credentials.password,
          ),
    );

    return _adoptSource(
      SourcesCompanion(
        name: Value(Uri.parse(credentials.serverUrl).host),
        sourceType: const Value(SourceType.xtream),
        serverUrl: Value(credentials.serverUrl),
        username: Value(credentials.username),
        password: Value(credentials.password),
      ),
    );
  }

  Future<int> _connectM3u() async {
    var url = _playlistUrl.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    await _probePlaylist(url);
    final epg = _epgUrl.text.trim();

    await _saveToBackend(
      () => ref
          .read(provisionRepositoryProvider)
          .saveM3uSource(m3uUrl: url, epgUrl: epg.isEmpty ? null : epg),
    );

    return _adoptSource(
      SourcesCompanion(
        name: Value(Uri.tryParse(url)?.host ?? 'Playlist'),
        sourceType: const Value(SourceType.m3u),
        serverUrl: Value(url),
        username: const Value(''),
        password: const Value(''),
        epgUrl: Value(epg.isEmpty ? null : epg),
      ),
    );
  }

  // Persist before replacing local data so failed saves remain retryable.
  Future<void> _saveToBackend(Future<void> Function() save) => save();

  /// Reads just the first chunks of the playlist to confirm it's reachable
  /// and looks like M3U — the full (possibly huge) download happens in sync.
  Future<void> _probePlaylist(String url) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.stream,
      ),
    );
    try {
      final response = await dio.get<ResponseBody>(url);
      final buffer = StringBuffer();
      await for (final chunk in response.data!.stream) {
        buffer.write(String.fromCharCodes(chunk));
        if (buffer.length >= 4096) break;
      }
      final head = buffer.toString();
      if (!head.contains('#EXT')) {
        throw Exception('That URL does not look like an M3U playlist.');
      }
    } on DioException catch (e) {
      throw Exception(switch (e.type) {
        DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
          'Connection timed out — check the URL.',
        DioExceptionType.badResponse =>
          'Server rejected the request (HTTP ${e.response?.statusCode}).',
        _ => 'Could not reach the server: ${e.message}',
      });
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // After a fresh login the router parks here while provisioning runs in
    // the background; when it delivers the account's playlist, leave without
    // requiring a manual connect. Guarded so a user editing an existing
    // playlist from Settings is never yanked away mid-form.
    ref.listen(activeSourceProvider, (prev, next) {
      if (!_connecting && prev?.value == null && next.value != null) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _buildForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Icon(Icons.play_circle_fill, color: AppColors.primary, size: 36),
              Text(
                'ZAUXOFLIX',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Connect your playlist',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          SegmentedButton<SourceType>(
            segments: const [
              ButtonSegment(
                value: SourceType.xtream,
                label: Text('Xtream Codes'),
                icon: Icon(Icons.dns_rounded, size: 18),
              ),
              ButtonSegment(
                value: SourceType.m3u,
                label: Text('M3U Playlist'),
                icon: Icon(Icons.playlist_play_rounded, size: 18),
              ),
            ],
            selected: {_type},
            onSelectionChanged: _connecting
                ? null
                : (s) => setState(() {
                    _type = s.first;
                    _error = null;
                  }),
          ),
          const SizedBox(height: 20),
          if (_type == SourceType.xtream)
            ..._xtreamFields()
          else
            ..._m3uFields(),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _connecting ? null : _connect,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _connecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Connect',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
          // Reached from Settings ("Change playlist") — offer a way
          // back that doesn't require connecting anything.
          if (context.canPop()) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _connecting ? null : () => context.pop(),
              child: const Text('Cancel'),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _xtreamFields() => [
    const Text(
      'Enter your Xtream Codes login details.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textSecondary),
    ),
    const SizedBox(height: 16),
    DpadTextField(
      builder: (context, fieldNode) => TextFormField(
        controller: _server,
        focusNode: fieldNode,
        enabled: !_connecting,
        decoration: const InputDecoration(
          labelText: 'Server URL',
          hintText: 'http://example.com:8080',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.url,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    ),
    const SizedBox(height: 14),
    DpadTextField(
      builder: (context, fieldNode) => TextFormField(
        controller: _username,
        focusNode: fieldNode,
        enabled: !_connecting,
        decoration: const InputDecoration(
          labelText: 'Username',
          border: OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    ),
    const SizedBox(height: 14),
    DpadTextField(
      builder: (context, fieldNode) => TextFormField(
        controller: _password,
        focusNode: fieldNode,
        enabled: !_connecting,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Password',
          border: OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        onFieldSubmitted: (_) => _connect(),
      ),
    ),
  ];

  List<Widget> _m3uFields() => [
    const Text(
      'Paste an M3U playlist URL. The TV guide (XMLTV) URL is optional —\nmost playlists advertise their own.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textSecondary),
    ),
    const SizedBox(height: 16),
    DpadTextField(
      builder: (context, fieldNode) => TextFormField(
        controller: _playlistUrl,
        focusNode: fieldNode,
        enabled: !_connecting,
        decoration: const InputDecoration(
          labelText: 'Playlist URL',
          hintText: 'http://example.com/playlist.m3u',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.url,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    ),
    const SizedBox(height: 14),
    DpadTextField(
      builder: (context, fieldNode) => TextFormField(
        controller: _epgUrl,
        focusNode: fieldNode,
        enabled: !_connecting,
        decoration: const InputDecoration(
          labelText: 'EPG URL (optional)',
          hintText: 'http://example.com/epg.xml',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.url,
        onFieldSubmitted: (_) => _connect(),
      ),
    ),
  ];
}
