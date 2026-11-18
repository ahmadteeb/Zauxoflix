import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Player gain for this app session, independent of the device volume.
final playerVolumeProvider = NotifierProvider<PlayerVolume, double>(
  PlayerVolume.new,
);

class PlayerVolume extends Notifier<double> {
  @override
  double build() => 1;

  void set(double value) => state = value.clamp(0.0, 1.0);
}

class PlayerVolumeButton extends StatelessWidget {
  const PlayerVolumeButton({
    super.key,
    required this.volume,
    required this.onChanged,
    required this.onInteraction,
  });

  final double volume;
  final ValueChanged<double> onChanged;
  final VoidCallback onInteraction;

  @override
  Widget build(BuildContext context) => MenuAnchor(
    onOpen: onInteraction,
    style: const MenuStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.surface),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    menuChildren: [
      SizedBox(
        width: 72,
        height: 220,
        child: Column(
          children: [
            Text(
              '${(volume * 100).round()}%',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  autofocus: true,
                  value: volume,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceLight,
                  semanticFormatterCallback: (value) =>
                      'Player volume ${(value * 100).round()} percent',
                  onChanged: (value) {
                    onChanged(value);
                    onInteraction();
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.volume_down_rounded, size: 20),
          ],
        ),
      ),
    ],
    builder: (context, controller, child) => IconButton(
      tooltip: 'Player volume',
      onPressed: () {
        onInteraction();
        controller.isOpen ? controller.close() : controller.open();
      },
      icon: Icon(
        volume == 0
            ? Icons.volume_off_rounded
            : volume < 0.5
            ? Icons.volume_down_rounded
            : Icons.volume_up_rounded,
        size: 26,
      ),
    ),
  );
}
