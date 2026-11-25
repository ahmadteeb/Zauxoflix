import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/discovery/discovery_repository.dart';
import '../../data/discovery/imdb_index.dart';
import '../../data/discovery/title_identity.dart';
import '../../data/discovery/trakt_client.dart';
import 'trailer_screen.dart';
import 'discovery_sections.dart';
import 'imdb_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/input/input_modality.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/tv/tv_back_button.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart' show CatalogKind;
import '../../core/widgets/media_artwork.dart';
import '../../core/widgets/skeleton.dart';

/// Shared Netflix-style details layout: backdrop, poster, metadata, Play.
/// Series screens pass [bottom] for the season/episode list.
class DetailsScaffold extends ConsumerWidget {
  const DetailsScaffold({
    super.key,
    required this.title,
    required this.onPlay,
    this.posterUrl,
    this.backdropUrl,
    this.discoveryKey,
    this.providerScore,
    this.metaLine = '',
    this.plot,
    this.cast,
    this.director,
    this.loadingDetails = false,
    this.playLabel = 'Play',
    this.playProgress,
    this.favorite,
    this.onToggleFavorite,
    this.onCast,
    this.extraActions = const [],
    this.bottom,
    this.episodesBuilder,
  });

  final String title;
  final VoidCallback? onPlay;
  final String? posterUrl;
  final String? backdropUrl;
  final CatalogTitle? discoveryKey;
  final String? providerScore;
  final String metaLine;
  final String? plot;
  final String? cast;
  final String? director;
  final bool loadingDetails;
  final String playLabel;

  /// 0..1 fraction shown under the Play button when a resume point exists.
  final double? playProgress;

  /// Non-null shows the My List toggle.
  final bool? favorite;
  final VoidCallback? onToggleFavorite;

  /// Non-null shows the cast button (play on another device).
  final VoidCallback? onCast;

  /// Rendered after the built-in buttons (e.g. the download action).
  final List<Widget> extraActions;
  final Widget? bottom;
  final Widget Function(bool showHeading)? episodesBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = discoveryKey;
    final discovery = key == null
        ? null
        : ref.watch(titleDiscoveryProvider(key)).value;
    final related = key == null
        ? null
        : ref.watch(relatedTitlesProvider(key)).value;
    final trailer = discovery?.trailer(
      View.of(context).platformDispatcher.locale.languageCode,
    );
    final imdb =
        validImdb(key?.external) ??
        discovery?.title.imdb ??
        (key == null
            ? null
            : ref
                  .watch(
                    localImdbIdProvider((
                      kind: key.kind,
                      name: key.name,
                      year: key.year,
                    )),
                  )
                  .asData
                  ?.value);
    final imdbData = imdb == null
        ? null
        : ref.watch(imdbTitleProvider(imdb)).asData?.value;
    final castId = imdb ?? discovery?.title.id.toString();
    final credits = key == null || castId == null
        ? const <CastCredit>[]
        : ref.watch(castCreditsProvider((key.kind, castId))).asData?.value ??
              const <CastCredit>[];
    final score = discovery?.rating;
    final metadata = [
      if (metaLine.isNotEmpty) metaLine,
      if (score != null)
        'Trakt ${score.toStringAsFixed(1)}/10'
      else
        ?providerScore,
    ].join('  ·  ');
    final size = MediaQuery.sizeOf(context);
    final compact =
        size.width < 900 || MediaQuery.textScalerOf(context).scale(16) > 24;

    final artKind = key?.kind == CatalogKind.series || episodesBuilder != null
        ? ArtworkKind.series
        : ArtworkKind.movie;
    final body = Stack(
      fit: StackFit.expand,
      children: [
        MediaArtwork(
          url: backdropUrl,
          title: title,
          kind: artKind,
          hasCaption: true,
          icon: Icons.movie_outlined,
          radius: 0,
          cacheWidth: 1280,
        ),
        // Darken + fade so text stays readable over any artwork.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Color(0xE60B0B0F), AppColors.background],
              stops: [0, 0.55, 0.8],
            ),
          ),
        ),
        SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 48,
              8,
              compact ? 20 : 48,
              40,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: kTvBuild
                    ? TvBackButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                      )
                    : BackButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black38,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact) ...[
                    MediaArtwork(
                      url: posterUrl,
                      title: title,
                      kind: artKind,
                      width: 220,
                      height: 330,
                      cacheWidth: 440,
                      radius: 12,
                      icon: Icons.movie_outlined,
                    ),
                    const SizedBox(width: 32),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: compact ? 28 : 40,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                          ),
                        ),
                        if (metadata.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            metadata,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (onPlay != null)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton.icon(
                                    autofocus: InputModality.usesDpad,
                                    onPressed: onPlay,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 28,
                                    ),
                                    label: Text(
                                      playLabel,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (playProgress case final progress?) ...[
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 160,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 3,
                                          backgroundColor:
                                              AppColors.surfaceLight,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            if (trailer != null)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    openTitleTrailer(context, trailer, title),
                                icon: const Icon(Icons.play_circle_outline),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                ),
                                label: const Text('Watch trailer'),
                              ),
                            if (favorite case final fav?)
                              OutlinedButton.icon(
                                onPressed: onToggleFavorite,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                icon: Icon(
                                  fav ? Icons.check_rounded : Icons.add_rounded,
                                  size: 24,
                                ),
                                label: const Text(
                                  'My List',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (onCast != null)
                              Tooltip(
                                message: 'Play on a device',
                                child: OutlinedButton(
                                  onPressed: onCast,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white54,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.cast_rounded,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ...extraActions,
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (loadingDetails)
                          const DetailsTextSkeleton()
                        else ...[
                          if (plot != null && imdbData != null)
                            Text(
                              'Provider synopsis',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          if (plot != null)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Text(
                                plot!,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          if (cast != null &&
                              (imdbData?.cast.isEmpty ?? true) &&
                              credits.isEmpty)
                            _CreditLine('Cast', cast!),
                          if (director != null)
                            _CreditLine('Director', director!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (imdb != null || credits.isNotEmpty) ...[
                const SizedBox(height: 24),
                ImdbDetails(
                  key: ValueKey((key?.source, key?.kind, key?.id)),
                  data: imdbData,
                  imdbId: imdb,
                  credits: credits,
                  origin: key == null
                      ? null
                      : (
                          source: key.source,
                          kind: key.kind,
                          id: key.id,
                          external:
                              imdb ??
                              key.external ??
                              (discovery == null
                                  ? null
                                  : 'trakt:${discovery.title.id}'),
                        ),
                ),
              ],
              if (episodesBuilder != null) ...[
                const SizedBox(height: 28),
                SeriesSections(
                  key: ValueKey((key?.source, key?.id)),
                  episodes: episodesBuilder!(
                    related == null || related.isEmpty,
                  ),
                  items: related ?? const [],
                ),
              ],
              if (episodesBuilder == null && bottom != null) ...[
                const SizedBox(height: 28),
                bottom!,
              ],
              if (episodesBuilder == null &&
                  related != null &&
                  related.isNotEmpty) ...[
                const SizedBox(height: 20),
                RelatedRail(items: related, inset: false),
              ],
            ],
          ),
        ),
      ],
    );
    void goBack() => Navigator.of(context).maybePop();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): goBack,
        const SingleActivator(LogicalKeyboardKey.goBack): goBack,
        const SingleActivator(LogicalKeyboardKey.browserBack): goBack,
      },
      child: Focus(
        autofocus: !InputModality.usesDpad,
        skipTraversal: true,
        child: body,
      ),
    );
  }
}

class _CreditLine extends StatelessWidget {
  const _CreditLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
