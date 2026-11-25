import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/media_item.dart';
import '../../../core/responsive/form_factor.dart';
import '../../../data/db/app_database.dart';
import '../../../data/discovery/discovery_repository.dart';
import '../../../data/discovery/home_catalog.dart';
import '../../../data/discovery/daily_cache.dart';
import '../../../data/discovery/home_feed.dart';
import '../../../data/discovery/home_ranking.dart';
import '../../../data/providers.dart';
import '../../details/media_navigation.dart';
import 'hero_banner.dart';
import 'spotlight_rotation.dart';

final _position = StreamProvider.autoDispose
    .family<PlaybackPosition?, (int, int)>(
      (ref, key) => ref
          .watch(databaseProvider)
          .watchPosition(key.$1, WatchKind.movie, key.$2),
    );

final _favorite = StreamProvider.autoDispose
    .family<bool, (int, CatalogKind, int)>(
      (ref, key) =>
          ref.watch(databaseProvider).watchIsFavorite(key.$1, key.$2, key.$3),
    );

class HomeSpotlight extends ConsumerStatefulWidget {
  const HomeSpotlight({
    super.key,
    required this.source,
    required this.formFactor,
    required this.fallback,
    required this.welcome,
  });
  final int source;
  final FormFactor formFactor;
  final Movie? fallback;
  final MediaItem welcome;
  @override
  ConsumerState<HomeSpotlight> createState() => _HomeSpotlightState();
}

class _HomeSpotlightState extends ConsumerState<HomeSpotlight>
    with WidgetsBindingObserver {
  HomeId? selected;
  HomeTime? selectedDuring;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(homeTimeProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final picks =
        ref.watch(homeDisplayFeedProvider(widget.source))?.featured ??
        const <HomePick>[];
    final slot = ref.watch(homeTimeProvider);
    final manual = selectedDuring == slot
        ? picks.indexWhere((p) => p.work.key == selected)
        : -1;
    final index = picks.isEmpty
        ? 0
        : manual >= 0
        ? manual
        : slot.part % picks.length;
    final pick = picks.isEmpty ? null : picks[index];
    final fallback = widget.fallback;
    final kind = pick?.work.kind ?? CatalogKind.vod,
        id = pick?.id ?? fallback?.streamId;
    if (id == null) {
      return HeroBanner(item: widget.welcome, formFactor: widget.formFactor);
    }
    final movie = kind == CatalogKind.vod;
    final info = movie ? ref.watch(catalogVodInfoProvider(id)).value : null;
    final imdb = pick?.work.imdbId;
    final backdrop = imdb == null
        ? null
        : ref.watch(homeBackdropProvider((kind, imdb))).value;
    final personal = pick?.reason.startsWith('Because') == true;
    final label = pick == null
        ? ''
        : personal
        ? 'Top pick for you'
        : pick.highlyRated
        ? 'Highly rated on IMDb'
        : 'Featured from your library';
    final item = MediaItem(
      id: id,
      type: movie ? MediaType.movie : MediaType.series,
      title: pick?.title ?? fallback!.name,
      subtitle: personal ? pick!.reason : info?.plot ?? pick?.work.plot ?? '',
      imageUrl:
          backdrop ??
          info?.backdrop ??
          (pick == null ? fallback?.icon : pick.imageUrl),
    );
    final meta = [
      item.kindLabel,
      if (pick?.work.imdb?.score case final rating?)
        'IMDb ${rating.toStringAsFixed(1)}/10'
      else if (pick == null && fallback != null)
        ?providerRating(fallback.rating, fallback.ratingScale),
      ?pick?.work.year ?? info?.releaseDate?.split('-').first,
      if (pick != null && pick.genres.isNotEmpty)
        pick.genres
            .take(2)
            .map((g) => g[0].toUpperCase() + g.substring(1))
            .join(' · ')
      else if (info?.genre case final genre? when genre.isNotEmpty)
        genre,
    ].join('  ·  ');
    final db = ref.watch(databaseProvider);
    final position = movie ? ref.watch(_position((widget.source, id))) : null;
    final favorite = ref.watch(_favorite((widget.source, kind, id)));
    final inList = favorite.value ?? false;
    return SpotlightRotation(
      slide: (slot, kind, id),
      index: index,
      count: picks.length,
      nextItem: picks.length > 1 ? picks[(index + 1) % picks.length] : null,
      onMove: (delta) => setState(() {
        selectedDuring = slot;
        selected = picks[(index + delta) % picks.length].work.key;
      }),
      builder: (navigation, hover) => HeroBanner(
        onControlHover: hover,
        item: item,
        formFactor: widget.formFactor,
        headlineLabel: label,
        metaLine: meta,
        navigation: navigation,
        playLabel: position?.value == null ? 'Play' : 'Resume',
        onPlay: movie && position?.hasValue == true
            ? () async {
                final selectedMovie = fallback?.streamId == id
                    ? fallback
                    : await db.getMovie(widget.source, id);
                if (context.mounted && selectedMovie != null) {
                  await playMovie(
                    context,
                    ref,
                    selectedMovie,
                    position: position?.value,
                    containerExtension: info?.containerExtension,
                  );
                }
              }
            : null,
        onDetails: () => openMediaItem(context, ref, item),
        inMyList: inList,
        onToggleMyList: !favorite.hasValue
            ? null
            : () => inList
                  ? db.removeFavorite(widget.source, kind, id)
                  : db.addFavorite(
                      sourceId: widget.source,
                      kind: kind,
                      itemId: id,
                      name: item.title,
                      imageUrl: pick?.imageUrl ?? item.imageUrl,
                    ),
      ),
    );
  }
}
