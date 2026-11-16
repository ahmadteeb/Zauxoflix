import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final externalLinkLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

Future<void> openExternalLink(
  BuildContext context,
  WidgetRef ref,
  Uri uri,
) async {
  var opened = false;
  try {
    opened = await ref.read(externalLinkLauncherProvider)(uri);
  } catch (_) {
    /* Devices without browsers can copy the link. */
  }
  if (opened || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Open on another device'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No browser could open this link. Copy it or open it on your phone or computer.',
            ),
            const SizedBox(height: 16),
            SelectableText(uri.toString()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: uri.toString()));
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Copy link'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
