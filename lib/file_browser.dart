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

import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/shared/viewers/image_viewer.dart';
import 'package:crowleys_cloud/shared/viewers/text_viewer.dart';
import 'package:crowleys_cloud/shared/widgets/breadcrumb_bar.dart';
import 'package:crowleys_cloud/shared/widgets/create_folder_dialog.dart';
import 'package:crowleys_cloud/shared/widgets/selection_action_bar.dart';
import 'package:crowleys_cloud/shared/widgets/selection_header_bar.dart';
import 'package:crowleys_cloud/smart_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// FileBrowser displays local filesystem files and folders in grid or list view.
///
/// Performance optimizations:
/// - Uses scoped [ListenableBuilder] widgets to restrict rebuilds to affected subtrees during selection/navigation.
/// - Delegates thumbnail rendering to [SmartThumbnail], which memoizes Futures and utilizes RAM + disk caching.
class FileBrowser extends StatefulWidget {
  final FileCategory category;
  final bool isGridView;
  final FileBrowserController? controller;
  final Future<void> Function(List<FileItem> items)? onUploadItems;

  const FileBrowser({
    super.key,
    required this.category,
    required this.isGridView,
    this.controller,
    this.onUploadItems,
  });

  @override
  State<FileBrowser> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowser> {
  late final FileBrowserController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? FileBrowserController(category: widget.category);
  }

  @override
  void dispose() {
    _controller.disposeController();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _onItemTap(FileItem item) async {
    if (_controller.isSelectionMode) {
      _controller.toggleSelection(item);
      return;
    }
    if (item.isDirectory) {
      await _controller.navigateInto(item.fsEntity as Directory);
      return;
    }
    await _openFile(item);
  }

  Future<void> _openFile(FileItem item) async {
    final filePath = await item.path;
    if (filePath.isEmpty || !mounted) return;

    if (photoExtensions.contains(item.type)) {
      final imageItems = _controller.files
          .where((f) => photoExtensions.contains(f.type))
          .toList();
      final initialIndex = imageItems.indexOf(item);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewer(
            imageItems: imageItems,
            initialIndex: initialIndex >= 0 ? initialIndex : 0,
            onUploadItem: (uploadItem) => _uploadItems([uploadItem]),
            onRenameItem: (renameItem) async {
              await _renameItem(renameItem);
            },
            onDeleteItem: (deleteItem) async {
              _controller.clearSelection();
              _controller.toggleSelection(deleteItem);
              await _deleteSelectedFiles();
            },
            onAddToFolderItem: (folderItem) async {
              _controller.clearSelection();
              _controller.toggleSelection(folderItem);
              await _addSelectedToFolder();
            },
          ),
        ),
      );
    } else if (textExtensions.contains(item.type)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextViewer(file: File(filePath)),
        ),
      );
    } else {
      await _controller.openFileExternally(item);
    }
  }

  Future<void> _deleteSelectedFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: appSurface,
          title: Text(l10n.deleteFilesTitle, style: TextStyle(color: appText)),
          content: Text(
            l10n.deleteFilesBody(_controller.selectedFiles.length),
            style: TextStyle(color: appSubtext),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _controller.deleteSelectedFiles();
    }
  }

  Future<void> _uploadItems(List<FileItem> items) async {
    final callback = widget.onUploadItems;
    if (callback == null) return;
    await callback(items);
    _controller.clearSelection();
  }

  Future<void> _createFolder() async {
    final name = await CreateFolderDialog.show(
      context,
      backgroundColor: appSurface,
      textColor: appText,
      hintColor: appSubtext,
    );
    if (name == null) return;
    final error = await _controller.createFolder(name);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? l10n.folderCreated)));
  }

  Future<String?> _pickLocalFolder() async {
    Directory? startDir;
    if (_controller.category.name == 'All files' &&
        _controller.directoryHistory.isNotEmpty) {
      startDir = _controller.directoryHistory.last;
    } else {
      final dirs = await getExternalStorageDirectories();
      if (dirs != null && dirs.isNotEmpty) {
        final root = extractRootPath(dirs.first.path);
        if (root != null) startDir = Directory(root);
      }
    }
    if (startDir == null) return null;
    if (!mounted) return null;

    final picked = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => LocalFolderPickerScreen(
          controller: _controller,
          initialPath: startDir!.path,
        ),
      ),
    );
    return picked;
  }

  Future<void> _addSelectedToFolder() async {
    final destination = await _pickLocalFolder();
    if (destination == null) return;
    final error = await _controller.moveSelectedToFolder(destination);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? l10n.movedToFolder)));
  }

  Future<void> _renameItem(FileItem item) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final controller = TextEditingController(text: item.name);
        return AlertDialog(
          backgroundColor: appSurface,
          title: Text(l10n.renameDialogTitle, style: TextStyle(color: appText)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: appText),
            decoration: InputDecoration(
              hintText: l10n.enterNewName,
              hintStyle: TextStyle(color: appSubtext),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(l10n.rename),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty || newName == item.name) return;
    final ok = await _controller.renameItem(item, newName);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final msg =
        _controller.operationMessage ??
        (ok ? l10n.renamedSuccessfully : l10n.renameFailed(''));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showContextMenu(BuildContext context, FileItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appSurface,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: appSubtext),
              title: Text(l10n.rename, style: TextStyle(color: appText)),
              onTap: () async {
                Navigator.pop(context);
                await _renameItem(item);
              },
            ),
            ListTile(
              leading: Icon(Icons.upload, color: appSubtext),
              title: Text(l10n.upload, style: TextStyle(color: appText)),
              onTap: () async {
                Navigator.pop(context);
                await _uploadItems([item]);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: appSubtext),
              title: Text(l10n.delete, style: TextStyle(color: appText)),
              onTap: () async {
                Navigator.pop(context);
                _controller.toggleSelection(item);
                await _deleteSelectedFiles();
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: appSubtext),
              title: Text(l10n.share, style: TextStyle(color: appText)),
              onTap: () async {
                Navigator.pop(context);
                _controller.toggleSelection(item);
                await _controller.shareSelectedFiles();
              },
            ),
            ListTile(
              leading: Icon(Icons.drive_file_move, color: appSubtext),
              title: Text(l10n.addToFolder, style: TextStyle(color: appText)),
              onTap: () async {
                Navigator.pop(context);
                _controller.toggleSelection(item);
                await _addSelectedToFolder();
              },
            ),
          ],
        );
      },
    );
  }

  List<({String label, String path})> _buildMainBreadcrumbItems(
    BuildContext context,
    String rootPath,
    String currentPath,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final separator = Platform.pathSeparator;
    if (currentPath == rootPath ||
        currentPath.startsWith('$rootPath$separator')) {
      final items = <({String label, String path})>[
        (label: l10n.storageRoot, path: rootPath),
      ];
      final relativePath = currentPath == rootPath
          ? ''
          : currentPath.substring(rootPath.length + 1);
      final segments = relativePath.split(separator).where((s) => s.isNotEmpty);
      var path = rootPath;
      for (final segment in segments) {
        path = '$path$separator$segment';
        items.add((label: segment, path: path));
      }
      return items;
    }

    final items = <({String label, String path})>[];
    final segments = p.split(currentPath).where((s) => s.isNotEmpty);
    var path = currentPath.startsWith(separator) ? separator : '';
    for (final segment in segments) {
      path = path == separator
          ? '$separator$segment'
          : path.isEmpty
          ? segment
          : '$path$separator$segment';
      items.add((label: segment, path: path));
    }
    return items;
  }

  Widget _buildMainBreadcrumb() {
    final currentDir = _controller.currentDirectory;
    if (widget.category.name != 'All files' ||
        _controller.isSelectionMode ||
        currentDir == null ||
        _controller.directoryHistory.isEmpty) {
      return const SizedBox.shrink();
    }
    final rootPath = _controller.directoryHistory.first.path;
    final items = _buildMainBreadcrumbItems(context, rootPath, currentDir.path);
    return BreadcrumbBar(
      items: items,
      onItemTap: (path) => _controller.navigateToDirectory(Directory(path)),
      backgroundColor: appSurface,
      textColor: appSubtext,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Column(
          children: [
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _HeaderControls(
                controller: _controller,
              ),
            ),
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _buildMainBreadcrumb(),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _FileListView(
                  controller: _controller,
                  isGridView: widget.isGridView,
                  onItemTap: _onItemTap,
                  onItemLongPress: _controller.toggleSelection,
                  onContextMenu: _showContextMenu,
                ),
              ),
            ),
          ],
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final showCreateFolder =
                !_controller.isSelectionMode &&
                widget.category.name == 'All files';
            if (!showCreateFolder) return const SizedBox.shrink();
            return Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _createFolder,
                backgroundColor: appAccent,
                foregroundColor: Colors.black,
                tooltip: l10n.newFolder,
                child: const Icon(Icons.create_new_folder),
              ),
            );
          },
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (!_controller.isSelectionMode) return const SizedBox.shrink();
            return _SelectionActionBar(
              onUpload: () => _uploadItems(_controller.selectedFiles.toList()),
              onDelete: _deleteSelectedFiles,
              onShare: _controller.shareSelectedFiles,
              onAddToFolder: _addSelectedToFolder,
              onRename: _controller.selectedFiles.length == 1
                  ? () => _renameItem(_controller.selectedFiles.first)
                  : null,
            );
          },
        ),
      ],
    );
  }
}

class _HeaderControls extends StatelessWidget {
  final FileBrowserController controller;

  const _HeaderControls({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (controller.isSelectionMode) {
      return SelectionHeaderBar(
        selectedCount: controller.selectedFiles.length,
        totalCount: controller.files.length,
        onSelectAll: controller.selectAll,
        onClearSelection: controller.clearSelection,
        textColor: appSubtext,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: appSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, color: appSubtext, size: 20),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<SortBy>(
                    value: controller.sortBy,
                    dropdownColor: appSurface,
                    style: TextStyle(color: appText),
                    icon: Icon(Icons.arrow_drop_down, color: appSubtext),
                    items: SortBy.values.map((v) {
                      String label;
                      switch (v) {
                        case SortBy.name:
                          label = l10n.name;
                          break;
                        case SortBy.date:
                          label = l10n.date;
                          break;
                        case SortBy.size:
                          label = l10n.size;
                          break;
                        case SortBy.type:
                          label = l10n.type;
                          break;
                      }
                      return DropdownMenuItem(value: v, child: Text(label));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        controller.updateSortBy(v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: appSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              splashRadius: 20,
              icon: Icon(
                controller.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: appSubtext,
              ),
              onPressed: controller.toggleSortDirection,
            ),
          ),
        ],
      ),
    );
  }
}

class LocalFolderPickerScreen extends StatefulWidget {
  const LocalFolderPickerScreen({
    super.key,
    required this.controller,
    required this.initialPath,
  });

  final FileBrowserController controller;
  final String initialPath;

  @override
  State<LocalFolderPickerScreen> createState() =>
      _LocalFolderPickerScreenState();
}

class _LocalFolderPickerScreenState extends State<LocalFolderPickerScreen> {
  late List<String> _pathStack;
  List<Directory> _folders = const [];
  Map<String, DateTime> _folderModifiedAt = const {};
  bool _loading = true;
  late SortBy _sortBy;
  late bool _sortAscending;
  late final String _navigationRootPath;

  String get _currentPath => _pathStack.last;
  bool get _isAtNavigationRoot => _currentPath == _navigationRootPath;
  bool get _canGoUp {
    if (_isAtNavigationRoot) return false;
    final parentPath = Directory(_currentPath).parent.path;
    return parentPath != _currentPath;
  }

  @override
  void initState() {
    super.initState();
    _pathStack = [widget.initialPath];
    _navigationRootPath = _resolveNavigationRootPath(widget.initialPath);
    _sortBy = widget.controller.sortBy;
    _sortAscending = widget.controller.sortAscending;
    _reload();
  }

  String _resolveNavigationRootPath(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length >= 3 &&
        segments[0] == 'storage' &&
        segments[1] == 'emulated') {
      return '/storage/emulated/${segments[2]}';
    }
    if (segments.length >= 2 && segments[0] == 'storage') {
      return '/storage/${segments[1]}';
    }
    return path;
  }

  bool _isUnderNavigationRoot(String path) {
    if (path == _navigationRootPath) return true;
    return path.startsWith('$_navigationRootPath${Platform.pathSeparator}');
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final dirs = await widget.controller.listDirectoriesAt(_currentPath);
    final modifiedAtEntries = await Future.wait(
      dirs.map((d) async {
        try {
          return MapEntry(d.path, (await d.stat()).modified);
        } catch (_) {
          return MapEntry(d.path, DateTime.fromMillisecondsSinceEpoch(0));
        }
      }),
    );
    final modifiedAt = Map<String, DateTime>.fromEntries(modifiedAtEntries);
    final sorted = _sortFolders(dirs, modifiedAt);
    if (!mounted) return;
    setState(() {
      _folders = sorted;
      _folderModifiedAt = modifiedAt;
      _loading = false;
    });
  }

  List<Directory> _sortFolders(
    List<Directory> dirs,
    Map<String, DateTime> modifiedAt,
  ) {
    final sorted = List<Directory>.from(dirs);
    int compareByName(Directory a, Directory b) =>
        a.path.toLowerCase().compareTo(b.path.toLowerCase());

    final compare = switch (_sortBy) {
      SortBy.name => compareByName,
      SortBy.date =>
        (Directory a, Directory b) =>
            modifiedAt[a.path]!.compareTo(modifiedAt[b.path]!),
      SortBy.size => compareByName,
      SortBy.type => compareByName,
    };
    sorted.sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
    return sorted;
  }

  void _applySorting() {
    setState(() {
      _folders = _sortFolders(_folders, _folderModifiedAt);
    });
  }

  Future<void> _goUp() async {
    if (!_canGoUp) return;
    if (_pathStack.length > 1) {
      setState(() => _pathStack.removeLast());
      await _reload();
      return;
    }

    final parentPath = Directory(_currentPath).parent.path;
    final nextPath = _isUnderNavigationRoot(parentPath)
        ? parentPath
        : _navigationRootPath;
    setState(() => _pathStack = [nextPath]);
    await _reload();
  }

  Future<void> _goToPath(String path) async {
    if (path == _currentPath) return;
    setState(() => _pathStack = [path]);
    await _reload();
  }

  List<({String label, String path})> _buildBreadcrumbItems(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (_isUnderNavigationRoot(_currentPath)) {
      final items = <({String label, String path})>[
        (label: l10n.storageRoot, path: _navigationRootPath),
      ];
      final basePrefix = '$_navigationRootPath${Platform.pathSeparator}';
      final relativePath = _currentPath == _navigationRootPath
          ? ''
          : _currentPath.startsWith(basePrefix)
          ? _currentPath.substring(basePrefix.length)
          : '';
      final segments = relativePath
          .split(Platform.pathSeparator)
          .where((s) => s.isNotEmpty);
      var current = _navigationRootPath;
      for (final segment in segments) {
        current = '$current${Platform.pathSeparator}$segment';
        items.add((label: segment, path: current));
      }
      return items;
    }

    final separator = Platform.pathSeparator;
    final items = <({String label, String path})>[];
    if (_currentPath.startsWith(separator)) {
      items.add((label: separator, path: separator));
    }
    final segments = _currentPath.split(separator).where((s) => s.isNotEmpty);
    var current = _currentPath.startsWith(separator) ? separator : '';
    for (final segment in segments) {
      current = current == separator
          ? '$separator$segment'
          : current.isEmpty
          ? segment
          : '$current$separator$segment';
      items.add((label: segment, path: current));
    }
    if (items.isEmpty) {
      items.add((label: _currentPath, path: _currentPath));
    }
    return items;
  }

  Widget _buildBreadcrumb(BuildContext context) {
    final items = _buildBreadcrumbItems(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: appSurface,
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
                  onPressed: () => _goToPath(items[i].path),
                  child: Text(
                    items[i].label,
                    style: TextStyle(color: appSubtext),
                  ),
                ),
                if (i < items.length - 1)
                  Icon(Icons.chevron_right, color: appSubtext, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createFolder() async {
    final name = await CreateFolderDialog.show(
      context,
      backgroundColor: appSurface,
      textColor: appText,
      hintColor: appSubtext,
    );
    if (name == null) return;
    final error = await widget.controller.createFolderAtPath(
      _currentPath,
      name,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? l10n.folderCreated)));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectFolder)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _createFolder,
                  icon: const Icon(Icons.create_new_folder),
                  label: Text(l10n.newFolder),
                ),
                const Spacer(),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: appSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sort, color: appSubtext, size: 20),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<SortBy>(
                          value: _sortBy,
                          dropdownColor: appSurface,
                          style: TextStyle(color: appText),
                          icon: Icon(Icons.arrow_drop_down, color: appSubtext),
                          items: SortBy.values.map((v) {
                            String label;
                            switch (v) {
                              case SortBy.name:
                                label = l10n.name;
                                break;
                              case SortBy.date:
                                label = l10n.date;
                                break;
                              case SortBy.size:
                                label = l10n.size;
                                break;
                              case SortBy.type:
                                label = l10n.type;
                                break;
                            }
                            return DropdownMenuItem(
                              value: v,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _sortBy = v);
                            _applySorting();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: appSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    splashRadius: 20,
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: appSubtext,
                    ),
                    onPressed: () {
                      setState(() => _sortAscending = !_sortAscending);
                      _applySorting();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _buildBreadcrumb(context),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Scrollbar(
                    thumbVisibility: true,
                    interactive: true,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_canGoUp)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.arrow_upward,
                                color: appSubtext,
                              ),
                              title: Text(
                                '..',
                                style: TextStyle(color: appText),
                              ),
                              onTap: _goUp,
                              tileColor: appSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ..._folders.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: Icon(Icons.folder, color: appAccent),
                              title: Text(
                                d.path.split('/').last,
                                style: TextStyle(color: appText),
                              ),
                              onTap: () {
                                setState(() => _pathStack.add(d.path));
                                _reload();
                              },
                              trailing: IconButton(
                                icon: Icon(Icons.check, color: appAccent),
                                onPressed: () => Navigator.pop(context, d.path),
                              ),
                              tileColor: appSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: appAccent,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.pop(context, _currentPath),
        icon: const Icon(Icons.check),
        label: Text(l10n.useThisFolder),
      ),
    );
  }
}

class _FileListView extends StatelessWidget {
  final FileBrowserController controller;
  final bool isGridView;
  final ValueChanged<FileItem> onItemTap;
  final ValueChanged<FileItem> onItemLongPress;
  final void Function(BuildContext context, FileItem item) onContextMenu;

  const _FileListView({
    required this.controller,
    required this.isGridView,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return Center(
        child: Text(l10n.errorWithMessage(controller.error.toString())),
      );
    }
    if (controller.files.isEmpty) {
      return Center(child: Text(l10n.noFilesFound));
    }

    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      thickness: 8,
      radius: const Radius.circular(4),
      child: isGridView
          ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: controller.files.length,
              itemBuilder: (_, i) => _GridItem(
                item: controller.files[i],
                isSelected: controller.selectedFiles.contains(
                  controller.files[i],
                ),
                onTap: () => onItemTap(controller.files[i]),
                onLongPress: () => onItemLongPress(controller.files[i]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.files.length,
              itemBuilder: (_, i) {
                final item = controller.files[i];
                return _ListItem(
                  item: item,
                  isSelected: controller.selectedFiles.contains(item),
                  isSelectionMode: controller.isSelectionMode,
                  onTap: () => onItemTap(item),
                  onLongPress: () => onItemLongPress(item),
                  onToggle: () => controller.toggleSelection(item),
                  onMenu: () => onContextMenu(context, item),
                );
              },
            ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final FileItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GridItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey(item.pathSync),
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: SmartThumbnail(item: item)),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: TextStyle(color: appText),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final FileItem item;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggle;
  final VoidCallback onMenu;

  const _ListItem({
    required this.item,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onToggle,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey(item.pathSync),
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: SmartThumbnail(item: item, isList: true),
        title: Text(item.name, style: TextStyle(color: appText)),
        trailing: isSelectionMode
            ? Checkbox(
                value: isSelected,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (_) => onToggle(),
              )
            : IconButton(
                icon: Icon(Icons.more_vert, color: appSubtext),
                onPressed: onMenu,
              ),
        onTap: onTap,
        onLongPress: onLongPress,
        tileColor: isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 1)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  final Future<void> Function() onUpload;
  final Future<void> Function() onDelete;
  final Future<void> Function() onShare;
  final Future<void> Function() onAddToFolder;
  final Future<void> Function()? onRename;

  const _SelectionActionBar({
    required this.onUpload,
    required this.onDelete,
    required this.onShare,
    required this.onAddToFolder,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SelectionActionBar(
      backgroundColor: appSurface,
      textColor: appText,
      iconColor: appSubtext,
      actions: [
        if (onRename != null)
          SelectionAction(
            icon: Icons.edit,
            label: l10n.rename,
            onPressed: onRename!,
          ),
        SelectionAction(
          icon: Icons.upload,
          label: l10n.upload,
          onPressed: onUpload,
        ),
        SelectionAction(
          icon: Icons.delete,
          label: l10n.delete,
          onPressed: onDelete,
        ),
        SelectionAction(
          icon: Icons.drive_file_move,
          label: l10n.addToFolder,
          onPressed: onAddToFolder,
        ),
        SelectionAction(
          icon: Icons.share,
          label: l10n.share,
          onPressed: onShare,
        ),
      ],
    );
  }
}
