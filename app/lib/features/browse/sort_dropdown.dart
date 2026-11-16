import 'package:flutter/material.dart';

import '../../core/input/input_modality.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tv/focusable.dart';
import '../../data/db/app_database.dart';

const _sortLabels = {
  CatalogSort.recentlyAdded: 'Recently added',
  CatalogSort.nameAsc: 'Name (A–Z)',
  CatalogSort.topRated: 'Top rated',
};

/// Sort-order picker for the browse grids. Opens a small dialog so it works
/// for touch, mouse and D-pad alike.
class SortDropdown extends StatelessWidget {
  const SortDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CatalogSort selected;
  final ValueChanged<CatalogSort> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDialog<CatalogSort>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _SortPickerDialog(selected: selected),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Focusable(
      onSelect: () => _openPicker(context),
      focusScale: 1.03,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sort_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              MediaQuery.sizeOf(context).width < 420 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20
                  ? 'Sort'
                  : _sortLabels[selected]!,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
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
    );
  }
}

class _SortPickerDialog extends StatelessWidget {
  const _SortPickerDialog({required this.selected});

  final CatalogSort selected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Text(
                'Sort by',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            FocusTraversalGroup(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in CatalogSort.values)
                      _SortTile(
                        label: _sortLabels[option]!,
                        selected: option == selected,
                        autofocus: option == selected && InputModality.usesDpad,
                        onSelect: () => Navigator.of(context).pop(option),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
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
