import 'package:flutter/material.dart';

import '../../core/input/input_modality.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tv/focusable.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/db/app_database.dart';

/// Category filter as a dropdown button. Opens a scrollable picker dialog
/// (works for touch, mouse and D-pad). `null` selection = All.
class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onChanged,
    required this.gutter,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final double gutter;

  String get _selectedLabel {
    if (selectedId == null) return 'All categories';
    for (final c in categories) {
      if (c.categoryId == selectedId) return c.name;
    }
    return 'All categories';
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDialog<_PickResult>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) =>
          _CategoryPickerDialog(categories: categories, selectedId: selectedId),
    );
    if (result != null) onChanged(result.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Focusable(
          onSelect: () => _openPicker(context),
          focusScale: 1.03,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      _selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 22,
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

/// Wrapper so "All" (null id) is distinguishable from dialog dismissal.
class _PickResult {
  const _PickResult(this.id);
  final String? id;
}

class _CategoryPickerDialog extends StatefulWidget {
  const _CategoryPickerDialog({
    required this.categories,
    required this.selectedId,
  });

  final List<Category> categories;
  final String? selectedId;

  @override
  State<_CategoryPickerDialog> createState() => _CategoryPickerDialogState();
}

class _CategoryPickerDialogState extends State<_CategoryPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.categories
        : widget.categories
              .where((c) => c.name.toLowerCase().contains(_query))
              .toList();
    final showAll = _query.isEmpty || 'all'.contains(_query);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.categories.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DpadTextField(
                builder: (context, fieldNode) => TextField(
                  controller: _searchController,
                  focusNode: fieldNode,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search categories…',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              child: FocusTraversalGroup(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                  itemCount: filtered.length + (showAll ? 1 : 0),
                  itemBuilder: (context, i) {
                    final (label, id) = showAll && i == 0
                        ? ('All categories', null)
                        : (
                            filtered[showAll ? i - 1 : i].name,
                            filtered[showAll ? i - 1 : i].categoryId,
                          );
                    final selected = widget.selectedId == id;
                    return _CategoryTile(
                      label: label,
                      selected: selected,
                      autofocus: selected && InputModality.usesDpad,
                      onSelect: () =>
                          Navigator.of(context).pop(_PickResult(id)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.selected,
    required this.autofocus,
    required this.onSelect,
  });

  final String label;
  final bool selected;
  final bool autofocus;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Focusable(
        onSelect: onSelect,
        autofocus: autofocus,
        focusScale: 1.01,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : null,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
