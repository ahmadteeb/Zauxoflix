import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/db/app_database.dart' show EpgProgramme;
import '../../data/live/live_directory.dart';
import '../../data/providers.dart';

Future<void> matchStationSchedule(
  BuildContext context,
  WidgetRef ref,
  LiveStation station,
  String? selected,
) async {
  final db = ref.read(databaseProvider);
  final source = ref.read(activeSourceProvider).value;
  if (source?.id != station.sourceId) return;
  final names = await db.liveGuideNamesFor(station.sourceId);
  if (!context.mounted) return;
  var query = '';
  final choice = await showAppSheet<String>(
    context,
    title: 'Match schedule',
    subtitle: station.name,
    icon: Icons.calendar_month_rounded,
    body: (sheet) => StatefulBuilder(
      builder: (context, setState) {
        final filter = liveNameKey(query);
        final entries = names.entries
            .where(
              (entry) =>
                  (filter.isEmpty &&
                      (entry.key == selected ||
                          entry.value.any(
                            (name) => liveNameKey(
                              name,
                            ).contains(liveNameKey(station.name)),
                          ))) ||
                  (filter.isNotEmpty &&
                      [
                        entry.key,
                        ...entry.value,
                      ].any((name) => liveNameKey(name).contains(filter))),
            )
            .take(60);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (names.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DpadTextField(
                  builder: (context, node) => TextField(
                    focusNode: node,
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search guide channel names',
                    ),
                  ),
                ),
              ),
            AppSheetOption(
              title: names.isEmpty ? 'Refresh guide' : 'Use automatic match',
              detail: names.isEmpty
                  ? 'Load schedules from this library’s guide source'
                  : null,
              icon: Icons.refresh_rounded,
              onPressed: () => Navigator.pop(sheet, ''),
            ),
            for (final entry in entries)
              AppSheetOption(
                title: entry.value.firstOrNull ?? entry.key,
                detail: entry.key,
                selected: selected == entry.key,
                icon: Icons.live_tv_outlined,
                onPressed: () => Navigator.pop(sheet, entry.key),
              ),
          ],
        );
      },
    ),
  );
  if (choice == null || !context.mounted) return;
  if (choice.isEmpty) {
    await db.resetLiveGuideLink(station.sourceId, station.key);
  } else {
    await db.saveLiveGuideLink(station.sourceId, station.key, choice);
  }
  if (!context.mounted ||
      ref.read(activeSourceProvider).value?.id != source!.id) {
    return;
  }
  final refreshed = await ref
      .read(syncControllerProvider.notifier)
      .syncSource(source, waitForGuide: true);
  final mapped =
      (await db.liveGuideLinksFor(station.sourceId))
          .where((entry) => entry.channelKey == station.key)
          .firstOrNull
          ?.guideId ??
      station.guideId;
  final programmes = mapped == null
      ? const <EpgProgramme>[]
      : await db.upcomingFor(
          station.sourceId,
          mapped,
          DateTime.now(),
          limit: 1,
        );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !refreshed
              ? 'Couldn’t refresh the guide'
              : programmes.isEmpty
              ? 'Schedule unavailable for this match'
              : 'Schedule updated',
        ),
      ),
    );
  }
}
