import 'package:flutter/material.dart';

import '../../core/input/input_modality.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/catalog_search.dart';
import '../../data/db/app_database.dart';

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    super.key,
    required this.formFactor,
    required this.categories,
    required this.selectedId,
    required this.onChanged,
    required this.gutter,
    this.blended = false,
    this.expand = false,
  });

  final FormFactor formFactor;
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final double gutter;
  final bool blended;
  final bool expand;

  Future<void> _openPicker(BuildContext context, String? selection) async {
    final picker = _CategoryPicker(
      categories: categories,
      selectedId: selection,
      remote: formFactor.isTv || InputModality.usesDpad,
      blended: blended,
    );
    final bottomSheet =
        formFactor == FormFactor.mobile &&
        (!blended || MediaQuery.orientationOf(context) == Orientation.portrait);
    final result = bottomSheet
        ? await showModalBottomSheet<_PickResult>(
            context: context,
            useSafeArea: true,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: AppColors.surface,
            barrierColor: const Color(0xAD000000),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(top: false, child: picker),
            ),
          )
        : await showDialog<_PickResult>(
            context: context,
            barrierColor: const Color(0xAD000000),
            builder: (context) => Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                side: blended
                    ? BorderSide.none
                    : const BorderSide(color: Colors.white10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: SizedBox(width: 560, child: picker),
            ),
          );
    if (context.mounted && result != null) onChanged(result.id);
  }

  @override
  Widget build(BuildContext context) {
    final category = categories
        .where((category) => category.categoryId == selectedId)
        .firstOrNull;
    final filtered = category != null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          label: 'Category filter',
          child: TextButton(
            onPressed: () => _openPicker(context, category?.categoryId),
            style:
                TextButton.styleFrom(
                      minimumSize: Size(expand ? double.infinity : 48, 48),
                      padding: const EdgeInsetsDirectional.only(
                        start: 13,
                        end: 11,
                      ),
                      backgroundColor: blended
                          ? AppColors.controlSurface
                          : AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    )
                    .copyWith(
                      side: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? const BorderSide(
                                color: AppColors.focusRing,
                                width: 2,
                              )
                            : blended
                            ? BorderSide.none
                            : BorderSide(
                                color: filtered
                                    ? AppColors.selectionAccent
                                    : Colors.white12,
                              ),
                      ),
                    )
                    .withSelectionGradient(filtered),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(
                  expand ? Icons.layers_outlined : Icons.tune_rounded,
                  size: 18,
                  color: filtered
                      ? AppColors.selectionAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 9),
                Flexible(
                  fit: expand ? FlexFit.tight : FlexFit.loose,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: expand ? double.infinity : 285,
                    ),
                    child: Text(
                      category?.name ?? 'All categories',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A null id clears the filter. A null result dismisses the picker.
class _PickResult {
  const _PickResult(this.id);
  final String? id;
}

class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.remote,
    required this.blended,
  });

  final List<Category> categories;
  final String? selectedId;
  final bool remote, blended;

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  final _search = TextEditingController();
  late final _searchKeys = [
    for (final category in widget.categories) catalogQuery(category.name),
  ];
  ScrollController? _scroll;
  String _query = '';

  void _filter(String text) {
    final query = catalogQuery(text);
    if (query != _query && (_scroll?.hasClients ?? false)) _scroll!.jumpTo(0);
    setState(() => _query = query);
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelSize = widget.remote ? 17.0 : 15.0;
    final extent = (MediaQuery.textScalerOf(context).scale(labelSize) + 30)
        .clamp(54.0, 96.0);
    final selectedIndex =
        widget.categories.indexWhere(
          (category) => category.categoryId == widget.selectedId,
        ) +
        1;
    _scroll ??= ScrollController(
      initialScrollOffset: widget.remote && selectedIndex > 2
          ? (selectedIndex - 2) * extent
          : 0,
    );
    const allLabel = 'All categories';
    final filtered = [
      if (_query.isEmpty || allLabel.toLowerCase().contains(_query))
        (label: allLabel, id: null as String?),
      for (final (index, category) in widget.categories.indexed)
        if (_searchKeys[index].contains(_query))
          (label: category.name, id: category.categoryId),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 540),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(22, 10, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close categories',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DpadTextField(
              borderRadius: BorderRadius.circular(13),
              builder: (context, fieldNode) => TextField(
                controller: _search,
                focusNode: fieldNode,
                onChanged: _filter,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search categories…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 21),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            _filter('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                  isDense: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            child: filtered.isEmpty
                ? const SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Text('No matching categories'),
                  )
                : FocusTraversalGroup(
                    child: ListView.builder(
                      controller: _scroll,
                      shrinkWrap: true,
                      itemExtent: extent,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final selected = widget.selectedId == option.id;
                        return Padding(
                          key: ValueKey(option.id),
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _CategoryOption(
                            label: option.label,
                            labelSize: labelSize,
                            blended: widget.blended,
                            selected: selected,
                            autofocus:
                                selected && widget.remote && _query.isEmpty,
                            onSelect: () => Navigator.of(
                              context,
                            ).pop(_PickResult(option.id)),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.label,
    required this.labelSize,
    required this.blended,
    required this.selected,
    required this.autofocus,
    required this.onSelect,
  });

  final String label;
  final double labelSize;
  final bool selected, autofocus, blended;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: TextButton(
        autofocus: autofocus,
        onPressed: onSelect,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const WidgetStatePropertyAll(
            EdgeInsetsDirectional.only(start: 15, end: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => !selected && states.contains(WidgetState.focused)
                ? AppColors.focusRing
                : blended
                ? Colors.transparent
                : AppColors.surfaceLight,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => !selected && states.contains(WidgetState.focused)
                ? AppColors.background
                : AppColors.textPrimary,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => selected && states.contains(WidgetState.focused)
                ? const BorderSide(color: AppColors.focusRing, width: 2)
                : BorderSide.none,
          ),
        ).withSelectionGradient(selected),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
