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
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';

class RestoreConflictItem {
  final int id;
  final String name;
  final String originalPath;
  final int existingSize;
  final DateTime existingModified;
  final int trashSize;
  final DateTime trashDeletedAt;

  const RestoreConflictItem({
    required this.id,
    required this.name,
    required this.originalPath,
    required this.existingSize,
    required this.existingModified,
    required this.trashSize,
    required this.trashDeletedAt,
  });

  factory RestoreConflictItem.fromJson(Map<String, dynamic> json) {
    return RestoreConflictItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      originalPath: (json['original_path'] as String?) ?? '',
      existingSize: (json['existing_size'] as num?)?.toInt() ?? 0,
      existingModified: DateTime.fromMillisecondsSinceEpoch(
        (json['existing_modified'] as num?)?.toInt() ?? 0,
      ),
      trashSize: (json['trash_size'] as num?)?.toInt() ?? 0,
      trashDeletedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['trash_deleted_at'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

class RestoreConflictResolution {
  final Map<int, bool> overwriteDecisions;

  const RestoreConflictResolution({required this.overwriteDecisions});
}

Future<RestoreConflictResolution?> showRestoreConflictDialog(
  BuildContext context, {
  required List<RestoreConflictItem> conflicts,
  required List<int> allIds,
}) {
  if (conflicts.isEmpty) {
    final decisions = <int, bool>{};
    for (final id in allIds) {
      decisions[id] = false;
    }
    return Future.value(
      RestoreConflictResolution(overwriteDecisions: decisions),
    );
  }

  return showDialog<RestoreConflictResolution>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) =>
        RestoreConflictDialog(conflicts: conflicts, allIds: allIds),
  );
}

class RestoreConflictDialog extends StatefulWidget {
  final List<RestoreConflictItem> conflicts;
  final List<int> allIds;

  const RestoreConflictDialog({
    super.key,
    required this.conflicts,
    required this.allIds,
  });

  @override
  State<RestoreConflictDialog> createState() => _RestoreConflictDialogState();
}

class _RestoreConflictDialogState extends State<RestoreConflictDialog> {
  int _currentIndex = 0;
  bool _applyToAll = false;
  final Map<int, bool> _decisions = {};

  RestoreConflictItem get _currentConflict => widget.conflicts[_currentIndex];
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
    // Fill any non-conflicting IDs with default false (restore as copy)
    for (final id in widget.allIds) {
      _decisions.putIfAbsent(id, () => false);
    }
    Navigator.of(
      context,
    ).pop(RestoreConflictResolution(overwriteDecisions: _decisions));
  }

  void _handleChoice(bool overwrite) {
    if (_applyToAll) {
      for (var i = _currentIndex; i < widget.conflicts.length; i++) {
        _decisions[widget.conflicts[i].id] = overwrite;
      }
      _finish();
      return;
    }

    _decisions[_currentConflict.id] = overwrite;
    if (_currentIndex + 1 < widget.conflicts.length) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finish();
    }
  }

  void _handleOverwriteAll() {
    for (var i = 0; i < widget.conflicts.length; i++) {
      _decisions[widget.conflicts[i].id] = true;
    }
    _finish();
  }

  void _handleKeepAllCopies() {
    for (var i = 0; i < widget.conflicts.length; i++) {
      _decisions[widget.conflicts[i].id] = false;
    }
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final conflict = _currentConflict;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      title: Row(
        children: [
          Icon(
            Icons.restore_page_rounded,
            color: theme.colorScheme.primary,
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
                    text: conflict.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: l10n.conflictAlreadyExistsAt),
                  TextSpan(
                    text: conflict.originalPath.isEmpty
                        ? conflict.name
                        : conflict.originalPath,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '.'),
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
                              Icons.folder_open,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.conflictInFolder,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.conflictSizeLabel(
                            _formatBytes(conflict.existingSize),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          l10n.conflictDateLabel(
                            _formatDate(conflict.existingModified, l10n),
                          ),
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.settings_backup_restore_rounded,
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
                              Icons.delete_outline,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.conflictFromTrash,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.conflictSizeLabel(
                            _formatBytes(conflict.trashSize),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          l10n.conflictDeletedLabel(
                            _formatDate(conflict.trashDeletedAt, l10n),
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
            onPressed: _handleKeepAllCopies,
            child: Text(l10n.conflictKeepAllCopies),
          ),
          OutlinedButton(
            onPressed: _handleOverwriteAll,
            child: Text(l10n.conflictOverwriteAll),
          ),
        ],
        OutlinedButton(
          onPressed: () => _handleChoice(false),
          child: Text(
            _applyToAll
                ? l10n.conflictRestoreAllAsCopies
                : l10n.conflictRestoreAsCopy,
          ),
        ),
        FilledButton(
          onPressed: () => _handleChoice(true),
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
