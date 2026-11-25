import '../../../data/discovery/discovery_repository.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/media_artwork.dart';
import '../../../data/providers.dart';

typedef CardPreviewData = ({String? image, String? summary, String metadata});
const emptyCardPreview = (image: null, summary: null, metadata: '');

/// Subscribed only after dwell or an explicit preview. Short-lived cache lets a
/// viewer move back a card without issuing another movie metadata request.
final catalogCardPreviewProvider = FutureProvider.autoDispose
    .family<CardPreviewData, (MediaType, int)>((ref, key) async {
      final source = ref.watch(activeSourceProvider).value;
      final db = ref.watch(databaseProvider);
      if (source == null) return emptyCardPreview;
      final (type, id) = key;
      late CardPreviewData data;
      switch (type) {
        case MediaType.movie:
          final infoFuture = ref.watch(catalogVodInfoProvider(id).future);
          final movie = await db.getMovie(source.id, id);
          final info = await infoFuture;
          data = (
            image: info?.backdrop,
            summary: info?.plot,
            metadata: [
              if (info?.releaseDate case final date? when date.length >= 4)
                date.substring(0, 4),
              ?info?.durationText,
              ?info?.genre,
              providerRating(movie?.rating, movie?.ratingScale) ?? '',
            ].where((s) => s.trim().isNotEmpty).join(' · '),
          );
        case MediaType.series:
          final series = await db.getSeriesItem(source.id, id);
          data = (
            image: null,
            summary: series?.plot,
            metadata: providerRating(series?.rating, series?.ratingScale) ?? '',
          );
        case MediaType.live:
          final channel = await db.getLiveChannel(source.id, id);
          final guide = channel?.epgChannelId;
          final now = DateTime.now();
          final current = guide == null
              ? null
              : (await db.upcomingFor(source.id, guide, now, limit: 1))
                    .where(
                      (p) => !p.startAt.isAfter(now) && p.endAt.isAfter(now),
                    )
                    .firstOrNull;
          if (ref.mounted) {
            final timer = Timer(
              current == null
                  ? const Duration(minutes: 1)
                  : current.endAt.difference(now),
              ref.invalidateSelf,
            );
            ref.onDispose(timer.cancel);
          }
          return (
            image: null,
            summary: current == null ? null : 'On now · ${current.title}',
            metadata: channel?.channelNumber == null
                ? ''
                : 'CH ${channel!.channelNumber}',
          );
      }
      if (ref.mounted) {
        final link = ref.keepAlive();
        final expiry = Timer(const Duration(minutes: 2), link.close);
        ref.onDispose(expiry.cancel);
      }
      return data;
    });

CardPreviewData previewFor(WidgetRef ref, MediaItem item) {
  final type = item.type, id = item.id;
  if (type == null || id == null) return emptyCardPreview;
  return ref.watch(catalogCardPreviewProvider((type, id))).value ??
      emptyCardPreview;
}

IconData mediaIcon(MediaType? type) => switch (type) {
  MediaType.live => Icons.live_tv_rounded,
  MediaType.series => Icons.video_library_outlined,
  _ => Icons.movie_outlined,
};

enum CardAction { select, details, remove }

class CatalogPreviewDialog extends ConsumerWidget {
  const CatalogPreviewDialog({
    super.key,
    required this.item,
    required this.canSelect,
    required this.hasDetails,
    required this.canRemove,
  });
  final MediaItem item;
  final bool canSelect, hasDetails, canRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = previewFor(ref, item);
    final meta = [
      item.kindLabel,
      data.metadata,
    ].where((s) => s.isNotEmpty).join('  ·  ');
    final details = [item.subtitle, if (data.summary != null) data.summary!]
        .where((s) => s.isNotEmpty && s != data.metadata && s != item.title)
        .toSet();
    final hasBackdrop =
        data.image?.isNotEmpty == true && data.image != item.imageUrl;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (meta.isNotEmpty)
          Text(
            meta,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 5),
        Text(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 25,
            height: 1.22,
          ),
        ),
      ],
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      constraints: const BoxConstraints(maxWidth: 460),
      clipBehavior: Clip.antiAlias,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                if (hasBackdrop) ...[
                  AspectRatio(
                    aspectRatio: 2.35,
                    child: MediaArtwork(
                      url: data.image ?? item.imageUrl,
                      icon: mediaIcon(item.type),
                      title: item.title,
                      kind: ArtworkKind.forMedia(item.type),
                      logo: item.type == MediaType.live,
                      radius: 0,
                      cacheWidth: 920,
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            AppColors.surface,
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [
                          Color.lerp(AppColors.surface, item.color, .35)!,
                          AppColors.surface,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        22,
                        44,
                        12,
                      ),
                      child: Row(
                        children: [
                          MediaArtwork(
                            url: item.imageUrl,
                            width: 84,
                            height: item.type == MediaType.live ? 64 : 126,
                            icon: mediaIcon(item.type),
                            logo: item.type == MediaType.live,
                            cacheWidth: 220,
                            title: item.title,
                            kind: ArtworkKind.forMedia(item.type),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: heading),
                        ],
                      ),
                    ),
                  ),
                PositionedDirectional(
                  end: 6,
                  top: 6,
                  child: IconButton.filled(
                    tooltip: 'Close preview',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasBackdrop) heading,
                  for (final text in details)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(text, style: const TextStyle(height: 1.4)),
                    ),
                  if (item.progress case final progress?)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        semanticsLabel: 'Watch progress',
                      ),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (canSelect)
                        FilledButton.icon(
                          autofocus: true,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () =>
                              Navigator.pop(context, CardAction.select),
                          icon: Icon(
                            item.continueWatching || item.type == MediaType.live
                                ? Icons.play_arrow_rounded
                                : Icons.info_outline_rounded,
                          ),
                          label: Text(item.actionLabel),
                        ),
                      if (hasDetails)
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, CardAction.details),
                          child: const Text(
                            'View details',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      if (canRemove)
                        IconButton(
                          tooltip: 'Remove from Continue Watching',
                          onPressed: () =>
                              Navigator.pop(context, CardAction.remove),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
