import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The LG embedder's Linux-plane fallback for the remote's evdev code 412.
const lgRemoteBackKey = LogicalKeyboardKey(0x180000019c);

class NavigateBackIntent extends Intent {
  const NavigateBackIntent();
}

/// Back action reachable by pointer and directional focus.
class TvBackButton extends StatelessWidget {
  const TvBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Back · Red remote button',
    child: TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(92, 48),
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.arrow_back_rounded),
      label: const Text('Back'),
    ),
  );
}
