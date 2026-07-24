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
    final bg = widget.backgroundColor ??
        theme.dialogTheme.backgroundColor ??
        theme.colorScheme.surface;
    final txt = widget.textColor ?? theme.textTheme.bodyLarge?.color;
    final hint = widget.hintColor ?? theme.hintColor;

    return AlertDialog(
      backgroundColor: bg,
      title: Text(
        widget.title,
        style: TextStyle(color: txt),
      ),
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
