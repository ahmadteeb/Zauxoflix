import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tv/focusable.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../browse/category_dropdown.dart';
import '../player/player_screen.dart';
import '../remote/cast_session.dart';
import '../shell/top_nav_bar.dart';

/// Channel list with an inline preview player. Selecting a channel plays it
/// in the mini player; selecting it again (or the fullscreen button) opens
/// the fullscreen player.
class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  final _searchController = TextEditingController();
  String? _categoryId;
  String _search = '';
  LiveChannel? _selected;
  // Latest list from the stream — lets fullscreen offer prev/next channel.
  List<LiveChannel> _channels = const [];
  // Unmounts the mini player (closing its stream) while the fullscreen
  // route is open — panels often allow a single connection.
  bool _miniSuspended = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onChannelSelected(LiveChannel channel) {
    // With a cast session active every selection zaps the target device;
    // the local mini preview stays off to spare the panel's connection.
    if (ref.read(castTargetProvider) != null) {
      setState(() => _selected = channel);
      _castChannel(channel);
      return;
    }
    if (_selected?.streamId == channel.streamId) {
      _openFullscreen();
    } else {
      setState(() => _selected = channel);
    }
  }

  Future<void> _castChannel(LiveChannel channel) async {
    final url = ref.read(playbackUrlsProvider)?.live(channel);
    if (url == null) return;
    await startPlayback(
      context,
      ref,
      PlayerArgs.single(
        url: url,
        title: channel.name,
        subtitle: channel.channelNumber == null
            ? ''
            : 'CH ${channel.channelNumber}',
        live: true,
        identity: PlaybackIdentity(
          itemType: 'LIVE',
          itemId: '${channel.streamId}',
        ),
      ),
    );
  }

  Future<void> _openFullscreen() async {
    final urls = ref.read(playbackUrlsProvider);
    final channel = _selected;
    if (urls == null || channel == null) return;
    if (ref.read(castTargetProvider) != null) {
      await _castChannel(channel);
      return;
    }
    final channels = (_channels.isEmpty ? [channel] : _channels)
        .where((c) => urls.live(c) != null)
        .toList();
    var initialIndex = channels.indexWhere(
      (c) => c.streamId == channel.streamId,
    );
    if (initialIndex < 0) initialIndex = 0;
    setState(() => _miniSuspended = true);
    // Wait for the mini player to unmount (freeing its stream) before the
    // fullscreen controller connects — panels often allow a single
    // connection, so the two must not overlap.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    // The player pops the index it ended on so channel zapping in
    // fullscreen keeps the list selection in sync.
    final lastIndex = await context.push<int>(
      '/player',
      extra: PlayerArgs(
        items: [
          for (final c in channels)
            PlayerItem(
              url: urls.live(c)!,
              title: c.name,
              subtitle: c.channelNumber == null ? '' : 'CH ${c.channelNumber}',
              live: true,
              identity: PlaybackIdentity(
                itemType: 'LIVE',
                itemId: '${c.streamId}',
              ),
            ),
        ],
        initialIndex: initialIndex,
      ),
    );
    if (!mounted) return;
    setState(() {
      _miniSuspended = false;
      if (lastIndex != null && lastIndex < channels.length) {
        _selected = channels[lastIndex];
      }
    });
  }

  Future<void> _openGuide() async {
    // Same as fullscreen: free the stream connection while the guide is on
    // top, in case the user starts playback from there.
    setState(() => _miniSuspended = true);
    await context.push('/guide');
    if (mounted) setState(() => _miniSuspended = false);
  }

  @override
  Widget build(BuildContext context) {
    final formFactor = formFactorOf(context, ref);
    final source = ref.watch(activeSourceProvider).value;
    final db = ref.watch(databaseProvider);
    final urls = ref.watch(playbackUrlsProvider);
    if (source == null || urls == null) return const SizedBox.shrink();
    // Inactive shell branches stay mounted (IndexedStack) but with
    // TickerMode(enabled: false). Dropping the nowPlaying subscription while
    // another tab is on top lets the (autoDispose) provider stop its poll.
    // ignore: deprecated_member_use
    final visible = TickerMode.of(context);
    final nowPlaying = visible
        ? (ref.watch(nowPlayingProvider).value ??
              const <String, EpgProgramme>{})
        : const <String, EpgProgramme>{};

    final gutter = formFactor.gutter;
    final compact = formFactor == FormFactor.mobile;
    final topPadding = compact ? 12.0 : kTopNavHeight + 12;

    final chips = Row(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: db.watchCategories(source.id, CatalogKind.live),
            builder: (context, snapshot) => CategoryDropdown(
              categories: snapshot.data ?? const [],
              selectedId: _categoryId,
              onChanged: (id) => setState(() => _categoryId = id),
              gutter: gutter,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: gutter),
          child: Focusable(
            onSelect: _openGuide,
            focusScale: 1.05,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_view_day_rounded,
                    size: 18,
                    semanticLabel: 'TV Guide',
                  ),
                  if (MediaQuery.sizeOf(context).width >= 500 &&
                      MediaQuery.textScalerOf(context).scale(14) <= 18) ...[
                    const SizedBox(width: 6),
                    const Text(
                      'TV Guide',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final searchField = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DpadTextField(
        builder: (context, fieldNode) => TextField(
          controller: _searchController,
          focusNode: fieldNode,
          onChanged: (text) => setState(() => _search = text.trim()),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search channels…',
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                  ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );

    final list = StreamBuilder(
      stream: db.watchLiveChannels(
        source.id,
        categoryId: _categoryId,
        limit: null,
      ),
      builder: (context, snapshot) {
        final query = _search.toLowerCase();
        final channels = [
          for (final c in snapshot.data ?? const <LiveChannel>[])
            if (query.isEmpty ||
                c.name.toLowerCase().contains(query) ||
                '${c.channelNumber}' == query)
              c,
        ];
        _channels = channels;
        if (!snapshot.hasData && !snapshot.hasError) {
          return const ChannelListSkeleton();
        }
        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.live_tv_rounded,
            title: 'Unable to load channels',
            message: 'Try reopening Live TV.',
          );
        }
        if (channels.isEmpty) {
          return EmptyState(
            icon: Icons.live_tv_rounded,
            title: query.isEmpty ? 'No live channels yet' : 'No matches',
            message: query.isEmpty
                ? (_categoryId == null
                      ? 'Sync your playlist to load channels.'
                      : 'This category is empty — try another one.')
                : 'No channels match “$_search”.',
          );
        }
        return FocusTraversalGroup(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: channels.length,
            itemBuilder: (context, i) {
              final channel = channels[i];
              return _ChannelTile(
                channel: channel,
                programme: channel.epgChannelId == null
                    ? null
                    : nowPlaying[channel.epgChannelId!.toLowerCase()],
                selected: channel.streamId == _selected?.streamId,
                onSelect: () => _onChannelSelected(channel),
              );
            },
          ),
        );
      },
    );

    final casting = ref.watch(castTargetProvider) != null;
    final preview = _PreviewPane(
      channel: _selected,
      suspended: _miniSuspended || !visible || casting,
      url: _selected == null ? null : urls.live(_selected!),
      upcoming: _selected?.epgChannelId == null
          ? null
          : db.upcomingFor(source.id, _selected!.epgChannelId!, DateTime.now()),
      onFullscreen: _openFullscreen,
      favoriteStream: _selected == null
          ? null
          : db.watchIsFavorite(
              source.id,
              CatalogKind.live,
              _selected!.streamId,
            ),
      onToggleFavorite: (favorite) {
        final channel = _selected;
        if (channel == null) return;
        favorite
            ? db.removeFavorite(source.id, CatalogKind.live, channel.streamId)
            : db.addFavorite(
                sourceId: source.id,
                kind: CatalogKind.live,
                itemId: channel.streamId,
                name: channel.name,
                imageUrl: channel.icon,
              );
      },
    );

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chips,
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
              child: compact
                  // Bound the preview so its 16:9 video shrinks (via the
                  // pane's inner Flexible) instead of overflowing when the
                  // viewport is short; the list always keeps some rows.
                  ? LayoutBuilder(
                      builder: (context, constraints) => Column(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: (constraints.maxHeight - 220).clamp(
                                120.0,
                                double.infinity,
                              ),
                            ),
                            child: preview,
                          ),
                          const SizedBox(height: 12),
                          searchField,
                          Expanded(child: list),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: (MediaQuery.sizeOf(context).width * 0.30)
                              .clamp(280.0, 380.0),
                          child: Column(
                            children: [
                              searchField,
                              Expanded(child: list),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: preview),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.channel,
    required this.programme,
    required this.selected,
    required this.onSelect,
  });

  final LiveChannel channel;
  final EpgProgramme? programme;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Focusable(
        onSelect: onSelect,
        focusScale: 1.02,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  channel.channelNumber?.toString() ?? '·',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                height: 30,
                child: channel.icon == null
                    ? const Icon(
                        Icons.live_tv_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      )
                    : AppImage(
                        url: channel.icon!,
                        fit: BoxFit.contain,
                        memCacheWidth: 96,
                        placeholderIconSize: 16,
                        errorWidget: const Icon(
                          Icons.live_tv_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (programme case final p?) ...[
                      const SizedBox(height: 2),
                      Text(
                        p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _ProgrammeProgress(programme: p),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.equalizer_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgrammeProgress extends StatelessWidget {
  const _ProgrammeProgress({required this.programme});

  final EpgProgramme programme;

  @override
  Widget build(BuildContext context) {
    final total = programme.endAt.difference(programme.startAt).inSeconds;
    final elapsed = DateTime.now().difference(programme.startAt).inSeconds;
    final progress = total <= 0 ? 0.0 : (elapsed / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 3,
        backgroundColor: AppColors.surfaceLight,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.channel,
    required this.url,
    required this.suspended,
    required this.upcoming,
    required this.onFullscreen,
    required this.favoriteStream,
    required this.onToggleFavorite,
  });

  final LiveChannel? channel;
  final String? url;
  final bool suspended;
  final Future<List<EpgProgramme>>? upcoming;
  final VoidCallback onFullscreen;
  final Stream<bool>? favoriteStream;
  final ValueChanged<bool> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final channel = this.channel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Flexible so a wide pane's 16:9 video can shrink instead of
        // overflowing the column when height is tight.
        Flexible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: channel == null || url == null
                  ? Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.live_tv_rounded,
                              size: 42,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 10),
                            Flexible(
                              child: Text(
                                'Select a channel to preview',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : suspended
                  ? Container(color: Colors.black)
                  : Focusable(
                      onSelect: onFullscreen,
                      focusScale: 1.0,
                      borderRadius: BorderRadius.circular(12),
                      child: _MiniPlayer(
                        key: ValueKey(channel.streamId),
                        url: url!,
                      ),
                    ),
            ),
          ),
        ),
        if (channel != null) ...[
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (channel.channelNumber != null)
                        Text(
                          'CH ${channel.channelNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (upcoming != null)
                        FutureBuilder(
                          future: upcoming,
                          builder: (context, snapshot) {
                            final programmes =
                                snapshot.data ?? const <EpgProgramme>[];
                            if (programmes.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final now = programmes.first;
                            final next = programmes.length > 1
                                ? programmes[1]
                                : null;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_formatTime(now.startAt)}–${_formatTime(now.endAt)}  ${now.title}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (now.description case final d?) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      d,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (next != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Next ${_formatTime(next.startAt)}  ${next.title}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                if (favoriteStream != null)
                  StreamBuilder(
                    stream: favoriteStream,
                    builder: (context, snapshot) {
                      final favorite = snapshot.data ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Focusable(
                          onSelect: () => onToggleFavorite(favorite),
                          focusScale: 1.05,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: favorite ? AppColors.primary : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                Focusable(
                  onSelect: onFullscreen,
                  focusScale: 1.05,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // Icon-only when the pane is too narrow for the label
                    // (e.g. desktop split view squeezed by a small window).
                    child: constraints.maxWidth < 320
                        ? const Icon(Icons.fullscreen_rounded, size: 20)
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen_rounded, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Fullscreen',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniPlayer extends StatefulWidget {
  const _MiniPlayer({super.key, required this.url});

  final String url;

  @override
  State<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<_MiniPlayer> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
          _controller.play();
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = '$e');
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Playback failed — try another channel.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          : ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, _) {
                if (value.hasError) {
                  return const Center(
                    child: Text(
                      'Playback failed — try another channel.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                if (!value.isInitialized) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  );
                }
                return Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio > 0
                        ? value.aspectRatio
                        : 16 / 9,
                    child: VideoPlayer(_controller),
                  ),
                );
              },
            ),
    );
  }
}
