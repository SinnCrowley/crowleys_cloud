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

typedef BreadcrumbItem = ({String label, String path});

/// Reusable interactive breadcrumb navigation bar with horizontal scrolling.
class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({
    super.key,
    required this.items,
    required this.onItemTap,
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.only(left: 16, right: 16, bottom: 8),
  });

  final List<BreadcrumbItem> items;
  final ValueChanged<String> onItemTap;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.surface;
    final txt = textColor ?? theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () => onItemTap(items[i].path),
                  child: Text(items[i].label, style: TextStyle(color: txt)),
                ),
                if (i < items.length - 1)
                  Icon(Icons.chevron_right, color: txt, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
