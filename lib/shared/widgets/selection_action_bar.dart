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

/// Configuration for a single action button inside [SelectionActionBar].
class SelectionAction {
  const SelectionAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onPressed;
  final Color? color;
}

/// Reusable floating bottom action bar presented during multi-item selection mode.
class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({
    super.key,
    required this.actions,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  final List<SelectionAction> actions;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  Widget _buildActionButton({
    required BuildContext context,
    required SelectionAction action,
    required Color defaultText,
    required Color defaultIcon,
  }) {
    final textColor = action.color ?? defaultText;
    final iconColor = action.color ?? defaultIcon;

    return InkWell(
      onTap: action.onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.surface;
    final txt = textColor ?? theme.textTheme.bodyLarge?.color;
    final icn = iconColor ?? theme.iconTheme.color;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: actions
                .map(
                  (action) => Expanded(
                    child: _buildActionButton(
                      context: context,
                      action: action,
                      defaultText: txt ?? Colors.white,
                      defaultIcon: icn ?? Colors.white70,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
