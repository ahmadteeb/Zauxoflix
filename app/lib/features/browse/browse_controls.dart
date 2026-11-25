import 'package:flutter/material.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/db/app_database.dart';
import 'category_dropdown.dart';

const _sortLabels = {
  CatalogSort.recentlyAdded: 'Recently added',
  CatalogSort.nameAsc: 'Name (A–Z)',
  CatalogSort.topRated: 'Top rated',
};

class BrowseControls extends StatelessWidget {
  const BrowseControls({
    super.key,
    required this.form,
    required this.kind,
    required this.categories,
    required this.categoryId,
    required this.sort,
    required this.search,
    required this.expanded,
    required this.onToggle,
    required this.onCategory,
    required this.onSort,
    required this.onSearch,
    required this.onReset,
    required this.filterFocus,
  });

  final FormFactor form;
  final CatalogKind kind;
  final List<Category> categories;
  final String? categoryId;
  final CatalogSort sort;
  final TextEditingController search;
  final bool expanded;
  final FocusNode filterFocus;
  final VoidCallback onToggle, onReset;
  final ValueChanged<String?> onCategory;
  final ValueChanged<CatalogSort> onSort;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: search,
    builder: (context, value, _) => _buildControls(context, value.text),
  );

  Widget _buildControls(BuildContext context, String searchText) {
    final movies = kind == CatalogKind.vod;
    final title = movies ? 'Movies' : 'Series';
    final padding = form == FormFactor.mobile ? 13.0 : 20.0;
    final hasSearch = searchText.trim().isNotEmpty;
    final hasSort = sort != CatalogSort.recentlyAdded;
    final extraFilters = hasSearch || hasSort;
    final filterCount =
        (categoryId != null ? 1 : 0) + (hasSearch ? 1 : 0) + (hasSort ? 1 : 0);
    final tinted = !MediaQuery.highContrastOf(context);
    final category = CategoryDropdown(
      formFactor: form,
      categories: categories,
      selectedId: categoryId,
      onChanged: onCategory,
      gutter: 0,
      blended: true,
      expand: true,
    );
    final heading = Semantics(
      header: true,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: form == FormFactor.mobile ? 32 : 45,
          height: 1.08,
          letterSpacing: -1.25,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
    final toggle = Semantics(
      expanded: expanded,
      child: TextButton.icon(
        focusNode: filterFocus,
        onPressed: onToggle,
        style: _controlStyle(context, selected: expanded || filterCount > 0),
        icon: Icon(
          expanded ? Icons.expand_less_rounded : Icons.tune_rounded,
          size: 19,
        ),
        label: Text(filterCount == 0 ? 'Filters' : 'Filters ($filterCount)'),
      ),
    );
    final sortLabel = Semantics(
      header: true,
      child: const Text(
        'Sort by',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final orderChoices = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final option in CatalogSort.values)
          Semantics(
            selected: option == sort,
            child: TextButton(
              style: _controlStyle(
                context,
                selected: option == sort,
                horizontalPadding: 10,
              ),
              onPressed: () => onSort(option),
              child: Text(_sortLabels[option]!),
            ),
          ),
      ],
    );
    final reset = TextButton(
      onPressed: onReset,
      style: _controlStyle(context, quiet: true),
      child: const Text('Clear filters'),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(form.isTv ? 24 : 20),
        color: tinted ? null : AppColors.surface,
        gradient: tinted ? AppColors.panelGradient : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
            final inline = constraints.maxWidth >= 660 && !largeText;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (largeText) ...[heading, const SizedBox(height: 10)],
                Row(
                  children: [
                    if (!largeText) ...[
                      Expanded(child: heading),
                      const SizedBox(width: 8),
                    ],
                    if (inline) ...[
                      Flexible(child: category),
                      const SizedBox(width: 10),
                    ],
                    toggle,
                  ],
                ),
                if (!inline) ...[const SizedBox(height: 10), category],
                if (expanded) ...[
                  const SizedBox(height: 12),
                  DpadTextField(
                    borderRadius: BorderRadius.circular(13),
                    builder: (context, focus) => TextField(
                      controller: search,
                      focusNode: focus,
                      onChanged: onSearch,
                      textInputAction: TextInputAction.search,
                      onSubmitted: onSearch,
                      decoration: InputDecoration(
                        labelText: movies ? 'Search movies' : 'Search series',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchText.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear title search',
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  search.clear();
                                  onSearch('');
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (inline)
                    Row(
                      children: [
                        sortLabel,
                        const SizedBox(width: 12),
                        Expanded(child: orderChoices),
                        if (filterCount > 0) reset,
                      ],
                    )
                  else ...[
                    sortLabel,
                    const SizedBox(height: 6),
                    orderChoices,
                  ],
                ],
                if (filterCount > 0 && (!inline || !expanded)) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (!expanded && extraFilters)
                        Text(
                          [
                            if (hasSearch) searchText.trim(),
                            if (hasSort) _sortLabels[sort]!,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      reset,
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

ButtonStyle _controlStyle(
  BuildContext context, {
  bool selected = false,
  bool quiet = false,
  double horizontalPadding = 12,
}) =>
    TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.textPrimary,
          backgroundColor: quiet
              ? Colors.transparent
              : AppColors.controlSurface,
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        )
        .copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const BorderSide(color: AppColors.focusRing, width: 2)
                : BorderSide.none,
          ),
        )
        .withSelectionGradient(selected);
