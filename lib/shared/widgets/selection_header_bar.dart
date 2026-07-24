import 'package:flutter/material.dart';

/// Reusable header bar displayed when multi-selection mode is active.
class SelectionHeaderBar extends StatelessWidget {
  const SelectionHeaderBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onClearSelection,
    this.textColor,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final isAllSelected = selectedCount == totalCount && totalCount > 0;
    final theme = Theme.of(context);
    final txt = textColor ?? theme.textTheme.bodyMedium?.color ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: isAllSelected,
            activeColor: theme.primaryColor,
            onChanged: (checked) =>
                checked == true ? onSelectAll() : onClearSelection(),
          ),
          Text(
            '$selectedCount selected',
            style: TextStyle(color: txt, fontSize: 16),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: txt),
            onPressed: onClearSelection,
          ),
        ],
      ),
    );
  }
}
