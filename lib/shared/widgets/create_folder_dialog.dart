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

/// Reusable dialog for prompting user to create a new folder.
class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({
    super.key,
    this.title = 'Create Folder',
    this.hintText = 'Folder name',
    this.backgroundColor,
    this.textColor,
    this.hintColor,
  });

  final String title;
  final String hintText;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;

  /// Helper static method to display the dialog and return the entered folder name.
  static Future<String?> show(
    BuildContext context, {
    String title = 'Create Folder',
    String hintText = 'Folder name',
    Color? backgroundColor,
    Color? textColor,
    Color? hintColor,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => CreateFolderDialog(
        title: title,
        hintText: hintText,
        backgroundColor: backgroundColor,
        textColor: textColor,
        hintColor: hintColor,
      ),
    );
  }

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg =
        widget.backgroundColor ??
        theme.dialogTheme.backgroundColor ??
        theme.colorScheme.surface;
    final txt = widget.textColor ?? theme.textTheme.bodyLarge?.color;
    final hint = widget.hintColor ?? theme.hintColor;

    return AlertDialog(
      backgroundColor: bg,
      title: Text(widget.title, style: TextStyle(color: txt)),
      content: TextField(
        controller: _inputController,
        autofocus: true,
        style: TextStyle(color: txt),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: hint),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_inputController.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
