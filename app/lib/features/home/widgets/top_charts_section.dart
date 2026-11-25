import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/responsive/form_factor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/db/app_database.dart';
import '../../../data/discovery/chart_sources.dart';
import '../../../data/discovery/daily_cache.dart';
import '../../../data/discovery/top_charts.dart';
import '../../details/media_navigation.dart';
import 'content_rail.dart';
import 'home_remote_navigation.dart';

class TopChartsSection extends ConsumerStatefulWidget {
  const TopChartsSection({
    super.key,
    required this.source,
    required this.formFactor,
    this.loadWhenVisible = false,
  });
  final int source;
  final FormFactor formFactor;
  final bool loadWhenVisible;
  @override
  ConsumerState<TopChartsSection> createState() => _TopChartsSectionState();
}

class _TopChartsSectionState extends ConsumerState<TopChartsSection> {
  ChartPeriod period = ChartPeriod.today;
  CatalogKind kind = CatalogKind.vod;
  ScrollPosition? _position;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.loadWhenVisible || _visible) return;
    final position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_checkVisibility);
      _position = position;
      _position?.addListener(_checkVisibility);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted || _visible) return;
    final position = _position;
    if (position != null) {
      final render = context.findRenderObject();
      if (render == null ||
          !render.attached ||
          !position.hasViewportDimension) {
        return;
      }
      final viewport = RenderAbstractViewport.maybeOf(render);
      if (viewport != null &&
          viewport.getOffsetToReveal(render, 0).offset >=
              position.pixels + position.viewportDimension) {
        return;
      }
    }
    _position?.removeListener(_checkVisibility);
    _position = null;
    setState(() => _visible = true);
  }

  @override
  void dispose() {
    _position?.removeListener(_checkVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = ref.watch(chartCountryProvider);
    final country = selectedCountry.value ?? 'JO';
    final regional = country != 'world';
    final q = (
      source: widget.source,
      region: country,
      period: period,
      kind: kind,
    );
    final value =
        widget.loadWhenVisible &&
            (!_visible ||
                (selectedCountry.isLoading && !selectedCountry.hasValue))
        ? const AsyncLoading<ChartResult>()
        : ref.watch(topChartProvider(q));
    final result = value.asData?.value;
    final day = ref.watch(recommendationDayProvider),
        gutter = widget.formFactor.gutter;
    final stamp = result?.day;
    void retry() {
      ref.read(dailyCacheProvider).retry(chartCacheKey(q), day);
      ref.invalidate(topChartProvider(q));
    }

    String date(String iso) => MaterialLocalizations.of(
      context,
    ).formatShortMonthDay(DateTime.parse(iso));
    final note = result == null
        ? ''
        : [
            result.provider,
            if (period == ChartPeriod.today)
              date(result.day)
            else if (result.through != null)
              'Through ${date(result.through!)}'
            else
              ?result.month,
            if (result.publishedCount > 0)
              '${result.entries.length} of ${result.publishedCount} available',
          ].join('  ·  ');
    final filters = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ChartSwitch<ChartPeriod>(
          choices: const {
            ChartPeriod.today: 'Today',
            ChartPeriod.month: 'This month',
          },
          selected: period,
          onSelect: (v) => setState(() => period = v),
        ),
        _ChartSwitch<CatalogKind>(
          choices: const {
            CatalogKind.vod: 'Movies',
            CatalogKind.series: 'Series',
          },
          selected: kind,
          onSelect: (v) => setState(() => kind = v),
        ),
        PopupMenuButton<String>(
          tooltip: 'Chart location',
          position: PopupMenuPosition.under,
          onSelected: (v) => ref.read(chartCountryProvider.notifier).select(v),
          itemBuilder: (_) => [
            for (final e in {'world': 'Worldwide', ...chartRegions}.entries)
              CheckedPopupMenuItem(
                value: e.key,
                checked: e.key == country,
                child: Text(e.value),
              ),
          ],
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xEE222229),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public_rounded, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      chartRegions[country] ?? 'Worldwide',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.expand_more_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(
              'Top 10',
              style: TextStyle(
                fontSize: widget.formFactor == FormFactor.mobile ? 35 : 48,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.8,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'in your library',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                  color: Color(0xffc4c2cb),
                ),
              ),
            ),
          ],
        ),
        if (note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Tooltip(
              message: period == ChartPeriod.today
                  ? 'Published chart positions'
                  : (regional
                        ? 'Weekly rank points, from 10 for first place to 1 for tenth.'
                        : 'Total reported weekly views this month.'),
              child: Text(
                note,
                style: const TextStyle(color: Color(0xffc4c2cb), fontSize: 14),
              ),
            ),
          ),
      ],
    );
    return ColoredBox(
      color: const Color(0xEB101015),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeFocusRow(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        if (bounds.maxWidth >=
                            1100 * MediaQuery.textScalerOf(context).scale(1)) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: heading),
                              const SizedBox(width: 16),
                              filters,
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            heading,
                            const SizedBox(height: 14),
                            filters,
                          ],
                        );
                      },
                    ),
                  ),
                  if (value.hasError || stamp != null && stamp != day)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: gutter,
                        vertical: 8,
                      ),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            stamp == null
                                ? 'The chart is unavailable.'
                                : 'Showing the saved chart from ${date(stamp)}.',
                          ),
                          TextButton(
                            onPressed: retry,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  if (result != null && result.entries.isEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 8),
                      child: Text(
                        result.publishedCount > 0
                            ? 'None of these chart titles are in your library. Try another chart or location.'
                            : period == ChartPeriod.month
                            ? 'No weekly results have been published for this selection yet.'
                            : 'No chart has been published for this selection.',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ContentRail(
              key: ValueKey((q.source, q.region, q.period, q.kind)),
              title: '',
              items: result?.entries ?? const [],
              formFactor: widget.formFactor,
              ranked: true,
              loading: value.isLoading && result == null,
              onSelect: (item) => openMediaItem(context, ref, item),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSwitch<T extends Object> extends StatelessWidget {
  const _ChartSwitch({
    required this.choices,
    required this.selected,
    required this.onSelect,
  });
  final Map<T, String> choices;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, choice) in choices.entries.indexed)
          Flexible(
            child: Semantics(
              selected: choice.key == selected,
              inMutuallyExclusiveGroup: true,
              child: TextButton(
                onPressed: () {
                  if (choice.key != selected) onSelect(choice.key);
                },
                style:
                    TextButton.styleFrom(
                          foregroundColor: choice.key == selected
                              ? AppColors.selectionAccent
                              : AppColors.textPrimary,
                          backgroundColor: AppColors.controlSurface,
                          textStyle: labelStyle,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(48, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusDirectional.horizontal(
                              start: index == 0
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                              end: index == choices.length - 1
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                            ),
                          ),
                        )
                        .copyWith(
                          side: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.focused)
                                ? const BorderSide(
                                    color: AppColors.focusRing,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                        )
                        .withSelectionGradient(choice.key == selected),
                child: Text(
                  choice.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
