import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/media_artwork.dart';
import '../../data/db/app_database.dart';
import '../../data/discovery/actor_library.dart';
import '../../data/discovery/imdb_index.dart';

class ActorLibrarySection extends ConsumerStatefulWidget {
  const ActorLibrarySection({super.key, required this.query});
  final ActorQuery query;
  @override
  ConsumerState<ActorLibrarySection> createState() =>
      _ActorLibrarySectionState();
}

class _ActorLibrarySectionState extends ConsumerState<ActorLibrarySection> {
  int rows = 1;
  void retry() {
    for (final kind in [CatalogKind.vod, CatalogKind.series]) {
      ref.invalidate(traktActingCreditsProvider((widget.query.personId, kind)));
    }
    ref.invalidate(imdbActingCreditsProvider(widget.query.personId));
    ref.invalidate(actorLibraryProvider(widget.query));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(actorLibraryProvider(widget.query));
    final data = state.value;
    final items = data?.items ?? const <ActorLibraryTitle>[];
    final width = math.min(
      608.0,
      math.max(1.0, MediaQuery.sizeOf(context).width - 80),
    );
    final columns =
        ((width + 12) /
                (134 * MediaQuery.textScalerOf(context).scale(16) / 16 + 12))
            .floor()
            .clamp(1, 4);
    final cardWidth = (width - 12 * (columns - 1)) / columns;
    final count = columns * rows;
    final checking = state.isLoading || data?.checking == true;
    final incomplete = state.hasError || data?.incomplete == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'In your library',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (items.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in items.take(count))
                SizedBox(
                  width: cardWidth,
                  child: _LibraryPoster(item: item, width: cardWidth),
                ),
            ],
          ),
        if (items.length > count)
          TextButton.icon(
            icon: const Icon(Icons.expand_more),
            onPressed: () => setState(() => rows += 2),
            label: const Text('Show more titles'),
          ),
        if (checking)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(
              semanticsLabel: 'Checking your library',
            ),
          ),
        if (!checking && items.isEmpty && !incomplete)
          const Text('No other matching movies or series in this library.'),
        if (incomplete && !checking)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                items.isEmpty
                    ? 'Couldn’t check all acting credits.'
                    : 'Some credits are unavailable.',
              ),
              TextButton(onPressed: retry, child: const Text('Retry')),
            ],
          ),
      ],
    );
  }
}

class _LibraryPoster extends StatelessWidget {
  const _LibraryPoster({required this.item, required this.width});
  final ActorLibraryTitle item;
  final double width;
  Widget _art(String? url) => MediaArtwork(
    title: item.title,
    kind: ArtworkKind.forMedia(item.type),
    url: url,
    width: width,
    height: width * 1.42,
    cacheWidth: 320,
    radius: 0,
    icon: item.type == MediaType.series
        ? Icons.tv_rounded
        : Icons.movie_outlined,
  );
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () => Navigator.of(context).pop(item),
    clipBehavior: Clip.antiAlias,
    style: OutlinedButton.styleFrom(
      padding: EdgeInsets.zero,
      alignment: Alignment.topLeft,
      foregroundColor: AppColors.textPrimary,
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MediaArtwork(
          title: item.title,
          kind: ArtworkKind.forMedia(item.type),
          url: item.creditPoster ?? item.imageUrl,
          fallbackArtwork: item.creditPoster != null
              ? (item.imageUrl != item.creditPoster
                    ? _art(item.imageUrl)
                    : null)
              : item.titleId == null
              ? null
              : Consumer(
                  builder: (context, ref, _) {
                    final url = ref
                        .watch(
                          actorTitlePosterProvider((
                            item.type == MediaType.series
                                ? CatalogKind.series
                                : CatalogKind.vod,
                            item.titleId!,
                          )),
                        )
                        .value;
                    return _art(url == item.imageUrl ? null : url);
                  },
                ),
          width: width,
          height: width * 1.42,
          cacheWidth: 320,
          radius: 0,
          icon: item.type == MediaType.series
              ? Icons.tv_rounded
              : Icons.movie_outlined,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: MediaQuery.textScalerOf(context).scale(14) * 2.6,
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontSize: 14, height: 1.3),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
