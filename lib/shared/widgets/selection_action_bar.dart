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
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        minimumSize: const Size.fromHeight(48),
      ),
      icon: Icon(action.icon, color: action.color ?? defaultIcon),
      label: Text(
        action.label,
        style: TextStyle(color: defaultText),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: action.onPressed,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
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
