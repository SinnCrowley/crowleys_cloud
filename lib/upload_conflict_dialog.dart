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
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';

enum UploadConflictAction { overwrite, skip }

class UploadConflictItem {
  final FileItem item;
  final ServerFileItem existingItem;

  const UploadConflictItem({required this.item, required this.existingItem});
}

class UploadConflictResolution {
  final List<FileItem> confirmedItems;
  final List<FileItem> skippedItems;

  const UploadConflictResolution({
    required this.confirmedItems,
    required this.skippedItems,
  });
}

Future<UploadConflictResolution?> showUploadConflictDialog(
  BuildContext context, {
  required List<UploadConflictItem> conflicts,
  required List<FileItem> nonConflictingItems,
}) {
  if (conflicts.isEmpty) {
    return Future.value(
      UploadConflictResolution(
        confirmedItems: nonConflictingItems,
        skippedItems: const [],
      ),
    );
  }

  return showDialog<UploadConflictResolution>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => UploadConflictDialog(
      conflicts: conflicts,
      nonConflictingItems: nonConflictingItems,
    ),
  );
}

class UploadConflictDialog extends StatefulWidget {
  final List<UploadConflictItem> conflicts;
  final List<FileItem> nonConflictingItems;

  const UploadConflictDialog({
    super.key,
    required this.conflicts,
    required this.nonConflictingItems,
  });

  @override
  State<UploadConflictDialog> createState() => _UploadConflictDialogState();
}

class _UploadConflictDialogState extends State<UploadConflictDialog> {
  int _currentIndex = 0;
  bool _applyToAll = false;
  late final List<FileItem> _confirmed;
  final List<FileItem> _skipped = [];

  @override
  void initState() {
    super.initState();
    _confirmed = List<FileItem>.from(widget.nonConflictingItems);
  }

  UploadConflictItem get _currentConflict => widget.conflicts[_currentIndex];
  bool get _isMultiConflict => widget.conflicts.length > 1;
  int get _remainingCount => widget.conflicts.length - _currentIndex;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    if (date.millisecondsSinceEpoch == 0) return l10n.unknown;
    final local = date.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  void _finish() {
    Navigator.of(context).pop(
      UploadConflictResolution(
        confirmedItems: _confirmed,
        skippedItems: _skipped,
      ),
    );
  }

  void _handleOverwrite() {
    if (_applyToAll) {
      for (var i = _currentIndex; i < widget.conflicts.length; i++) {
        _confirmed.add(widget.conflicts[i].item);
      }
      _finish();
      return;
    }

    _confirmed.add(_currentConflict.item);
    if (_currentIndex + 1 < widget.conflicts.length) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finish();
    }
  }

  void _handleSkip() {
    if (_applyToAll) {
      for (var i = _currentIndex; i < widget.conflicts.length; i++) {
        _skipped.add(widget.conflicts[i].item);
      }
      _finish();
      return;
    }

    _skipped.add(_currentConflict.item);
    if (_currentIndex + 1 < widget.conflicts.length) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finish();
    }
  }

  void _handleOverwriteAll() {
    for (var i = _currentIndex; i < widget.conflicts.length; i++) {
      _confirmed.add(widget.conflicts[i].item);
    }
    _finish();
  }

  void _handleSkipAll() {
    for (var i = _currentIndex; i < widget.conflicts.length; i++) {
      _skipped.add(widget.conflicts[i].item);
    }
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final conflict = _currentConflict;
    final existing = conflict.existingItem;
    final incoming = conflict.item;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.conflictFileAlreadyExists,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isMultiConflict)
                  Text(
                    l10n.conflictNofM(
                      _currentIndex + 1,
                      widget.conflicts.length,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            splashRadius: 18,
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(text: l10n.conflictAFileNamed),
                  TextSpan(
                    text: incoming.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: l10n.conflictAlreadyExistsInFolder),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.conflictExisting,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.conflictSizeLabel(_formatBytes(existing.size)),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          l10n.conflictDateLabel(
                            _formatDate(existing.modifiedAt, l10n),
                          ),
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.upload_file,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.conflictNewUpload,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.conflictSizeLabel(_formatBytes(incoming.size)),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          l10n.conflictDateLabel(
                            _formatDate(incoming.modifiedDate, l10n),
                          ),
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isMultiConflict) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _applyToAll = !_applyToAll),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _applyToAll,
                        onChanged: (val) =>
                            setState(() => _applyToAll = val ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.conflictApplyToRemaining(_remainingCount),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_isMultiConflict) ...[
          OutlinedButton(
            onPressed: _handleSkipAll,
            child: Text(l10n.conflictSkipAll),
          ),
          OutlinedButton(
            onPressed: _handleOverwriteAll,
            child: Text(l10n.conflictOverwriteAll),
          ),
        ],
        OutlinedButton(
          onPressed: _handleSkip,
          child: Text(
            _applyToAll ? l10n.conflictSkipAllRemaining : l10n.conflictSkip,
          ),
        ),
        FilledButton(
          onPressed: _handleOverwrite,
          child: Text(
            _applyToAll
                ? l10n.conflictOverwriteAllRemaining
                : l10n.conflictOverwrite,
          ),
        ),
      ],
    );
  }
}
