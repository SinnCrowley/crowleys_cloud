import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/shared/viewers/image_viewer.dart';
import 'package:crowleys_cloud/shared/viewers/text_viewer.dart';
import 'package:crowleys_cloud/smart_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Delete Files?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${_controller.selectedFiles.length} selected items? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
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
    final inputController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Create Folder',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: inputController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(inputController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null) return;
    final error = await _controller.createFolder(name);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Folder created.')));
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
        builder: (_) => _LocalFolderPickerScreen(
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Moved to folder.')));
  }

  void _showContextMenu(BuildContext context, FileItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appSurface,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.upload, color: Colors.white70),
            title: const Text('Upload', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              await _uploadItems([item]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.white70),
            title: const Text('Delete', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              _controller.toggleSelection(item);
              await _deleteSelectedFiles();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white70),
            title: const Text('Share', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              _controller.toggleSelection(item);
              await _controller.shareSelectedFiles();
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move, color: Colors.white70),
            title: const Text(
              'Add to folder',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              _controller.toggleSelection(item);
              await _addSelectedToFolder();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            Column(
              children: [
                _HeaderControls(
                  controller: _controller,
                  showCreateFolder: widget.category.name == 'All files',
                  onCreateFolder: _createFolder,
                ),
                Expanded(
                  child: _FileListView(
                    controller: _controller,
                    isGridView: widget.isGridView,
                    onItemTap: _onItemTap,
                    onItemLongPress: _controller.toggleSelection,
                    onContextMenu: _showContextMenu,
                  ),
                ),
              ],
            ),
            if (_controller.isSelectionMode)
              _SelectionActionBar(
                onUpload: () =>
                    _uploadItems(_controller.selectedFiles.toList()),
                onDelete: _deleteSelectedFiles,
                onShare: _controller.shareSelectedFiles,
                onAddToFolder: _addSelectedToFolder,
              ),
          ],
        );
      },
    );
  }
}

class _HeaderControls extends StatelessWidget {
  final FileBrowserController controller;
  final bool showCreateFolder;
  final Future<void> Function() onCreateFolder;

  const _HeaderControls({
    required this.controller,
    required this.showCreateFolder,
    required this.onCreateFolder,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
        child: Row(
          children: [
            Checkbox(
              value:
                  controller.selectedFiles.length == controller.files.length &&
                  controller.files.isNotEmpty,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (checked) => checked == true
                  ? controller.selectAll()
                  : controller.clearSelection(),
            ),
            Text(
              '${controller.selectedFiles.length} selected',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: controller.clearSelection,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Row(
        children: [
          if (showCreateFolder)
            FilledButton.icon(
              onPressed: onCreateFolder,
              icon: const Icon(Icons.create_new_folder),
              label: const Text('New folder'),
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
                const Icon(Icons.sort, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<SortBy>(
                    value: controller.sortBy,
                    dropdownColor: const Color(0xFF333333),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                    items: SortBy.values
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              v.name[0].toUpperCase() + v.name.substring(1),
                            ),
                          ),
                        )
                        .toList(),
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
                color: Colors.white70,
              ),
              onPressed: controller.toggleSortDirection,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalFolderPickerScreen extends StatefulWidget {
  const _LocalFolderPickerScreen({
    required this.controller,
    required this.initialPath,
  });

  final FileBrowserController controller;
  final String initialPath;

  @override
  State<_LocalFolderPickerScreen> createState() =>
      _LocalFolderPickerScreenState();
}

class _LocalFolderPickerScreenState extends State<_LocalFolderPickerScreen> {
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

  List<({String label, String path})> _buildBreadcrumbItems() {
    if (_isUnderNavigationRoot(_currentPath)) {
      final items = <({String label, String path})>[
        (label: 'Storage', path: _navigationRootPath),
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

  Widget _buildBreadcrumb() {
    final items = _buildBreadcrumbItems();
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
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                if (i < items.length - 1)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                    size: 18,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createFolder() async {
    final input = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Create Folder',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: input,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, input.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null) return;
    final error = await widget.controller.createFolderAtPath(
      _currentPath,
      name,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Folder created.')));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Folder')),
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
                  label: const Text('New folder'),
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
                      const Icon(Icons.sort, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<SortBy>(
                          value: _sortBy,
                          dropdownColor: const Color(0xFF333333),
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white70,
                          ),
                          items: SortBy.values
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    v.name[0].toUpperCase() +
                                        v.name.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
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
                      color: Colors.white70,
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
          _buildBreadcrumb(),
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
                              leading: const Icon(
                                Icons.arrow_upward,
                                color: Colors.white70,
                              ),
                              title: const Text(
                                '..',
                                style: TextStyle(color: Colors.white70),
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
                              leading: const Icon(
                                Icons.folder,
                                color: Colors.white70,
                              ),
                              title: Text(
                                d.path.split('/').last,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              onTap: () {
                                setState(() => _pathStack.add(d.path));
                                _reload();
                              },
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white70,
                                ),
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
        onPressed: () => Navigator.pop(context, _currentPath),
        icon: const Icon(Icons.check),
        label: const Text('Use this folder'),
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
    if (controller.isLoading && controller.files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return Center(child: Text('Error: ${controller.error}'));
    }
    if (controller.files.isEmpty) {
      return const Center(child: Text('No files found.'));
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
                style: const TextStyle(color: Colors.white70),
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
        title: Text(item.name, style: const TextStyle(color: Colors.white70)),
        trailing: isSelectionMode
            ? Checkbox(
                value: isSelected,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (_) => onToggle(),
              )
            : IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
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

  const _SelectionActionBar({
    required this.onUpload,
    required this.onDelete,
    required this.onShare,
    required this.onAddToFolder,
  });

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Future<void> Function() onPressed,
  }) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        minimumSize: const Size.fromHeight(48),
      ),
      icon: Icon(icon, color: Colors.white70),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _buildActionButton(
        icon: Icons.upload,
        label: 'Upload',
        onPressed: onUpload,
      ),
      _buildActionButton(
        icon: Icons.delete,
        label: 'Delete',
        onPressed: onDelete,
      ),
      _buildActionButton(
        icon: Icons.drive_file_move,
        label: 'Add to folder',
        onPressed: onAddToFolder,
      ),
      _buildActionButton(icon: Icons.share, label: 'Share', onPressed: onShare),
    ];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: appBackground,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useSingleRow = constraints.maxWidth >= 664;
            if (useSingleRow) {
              return Row(
                children: buttons
                    .map((button) => Expanded(child: button))
                    .toList(),
              );
            }

            final itemWidth = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: buttons
                  .map((button) => SizedBox(width: itemWidth, child: button))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
