// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

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
