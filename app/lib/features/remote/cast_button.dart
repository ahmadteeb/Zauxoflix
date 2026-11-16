import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'cast_session.dart';

/// Nav-bar entry point for the cast session. Never shown on TV builds —
/// callers gate on [kTvBuild].
class CastButton extends ConsumerWidget {
  const CastButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(castTargetProvider);
    final connected = target != null;
    return IconButton(
      tooltip: connected
          ? 'Casting to ${target.displayName}'
          : 'Cast to a device',
      onPressed: () => showCastSheet(context, ref),
      style: IconButton.styleFrom(
        backgroundColor: connected
            ? AppColors.primary.withValues(alpha: .18)
            : Colors.transparent,
      ),
      icon: Icon(
        connected ? Icons.cast_connected_rounded : Icons.cast_rounded,
        size: 22,
        color: connected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}
