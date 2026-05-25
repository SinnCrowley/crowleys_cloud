import 'dart:async';
import 'dart:typed_data';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class ServerFileBrowser extends StatefulWidget {
  const ServerFileBrowser({
    super.key,
    required this.controller,
    required this.isGridView,
  });

  final ServerBrowserController controller;
  final bool isGridView;

  @override
  State<ServerFileBrowser> createState() => _ServerFileBrowserState();
}

class _ServerFileBrowserState extends State<ServerFileBrowser> {
  ServerBrowserController get controller => widget.controller;
  bool get isGridView => widget.isGridView;

  Future<void> _onTapItem(ServerFileItem item) async {
    if (controller.isSelectionMode) {
      controller.toggleSelection(item);
      return;
    }
    if (item.isDir) {
      await controller.navigateInto(item);
      return;
    }

    final temp = await controller.downloadTempForEdit(item);
    if (temp != null) {
      await OpenFile.open(temp.path);
    }
  }

  Future<void> _deleteSelectedFiles() async {
    final selectedCount = controller.selectedFiles.length;
    if (selectedCount == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Delete Files?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete $selectedCount selected items? This action cannot be undone.',
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
      await controller.deleteSelectedFiles();
      _showOperationMessage();
    }
  }

  Future<void> _downloadSelectedFiles() async {
    await controller.downloadSelectedFiles();
    _showOperationMessage();
  }

  Future<void> _shareSelectedFiles() async {
    await controller.shareSelectedFiles();
    _showOperationMessage();
  }

  Future<void> _shareSelectedInServer() async {
    await controller.shareSelectedInServer();
    _showOperationMessage();
  }

  Future<void> _showShareOptions() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: appSurface,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.link, color: Colors.white70),
            title: const Text(
              'Share via link',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _shareSelectedFiles();
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_shared, color: Colors.white70),
            title: const Text(
              'Share in server',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _shareSelectedInServer();
            },
          ),
        ],
      ),
    );
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
    await controller.createFolder(name);
    _showOperationMessage();
  }

  Future<String?> _pickServerFolder() async {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _ServerFolderPickerScreen(
          controller: controller,
          initialPath: controller.currentPath,
        ),
      ),
    );
  }

  Future<void> _addSelectedToFolder() async {
    final destination = await _pickServerFolder();
    if (destination == null) return;
    await controller.moveSelectedToFolder(destination);
    _showOperationMessage();
  }

  void _showOperationMessage() {
    final msg = controller.operationMessage;
    if (msg == null || msg.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showContextMenu(BuildContext context, ServerFileItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appSurface,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white70),
            title: const Text(
              'Download',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              controller.toggleSelection(item);
              await _downloadSelectedFiles();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.white70),
            title: const Text('Delete', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              controller.toggleSelection(item);
              await _deleteSelectedFiles();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white70),
            title: const Text(
              'Share via link',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              controller.toggleSelection(item);
              await _shareSelectedFiles();
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_shared, color: Colors.white70),
            title: const Text(
              'Share in server',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              controller.toggleSelection(item);
              await _shareSelectedInServer();
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
              controller.toggleSelection(item);
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
      animation: controller,
      builder: (context, _) {
        return Stack(
          children: [
            Column(
              children: [
                _ServerHeaderControls(
                  controller: controller,
                  showCreateFolder: controller.selectedType == 'all',
                  onCreateFolder: _createFolder,
                ),
                Expanded(child: _buildContent()),
              ],
            ),
            if (controller.isSelectionMode)
              _SelectionActionBar(
                onDownload: _downloadSelectedFiles,
                onDelete: _deleteSelectedFiles,
                onShare: _showShareOptions,
                onAddToFolder: _addSelectedToFolder,
              ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
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
              itemCount: controller.files.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, i) => _GridItem(
                controller: controller,
                item: controller.files[i],
                isSelected: controller.selectedFiles.contains(
                  controller.files[i],
                ),
                onTap: () => _onTapItem(controller.files[i]),
                onLongPress: () =>
                    controller.toggleSelection(controller.files[i]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.files.length,
              itemBuilder: (context, i) {
                final item = controller.files[i];
                return _ListItem(
                  controller: controller,
                  item: item,
                  isSelected: controller.selectedFiles.contains(item),
                  onTap: () => _onTapItem(item),
                  onLongPress: () => controller.toggleSelection(item),
                  onToggle: () => controller.toggleSelection(item),
                  onMenu: () => _showContextMenu(context, item),
                );
              },
            ),
    );
  }
}

IconData _iconForFile(ServerFileItem item) {
  final ext = item.extension.startsWith('.')
      ? item.extension.substring(1)
      : item.extension;
  return switch (ext) {
    'pdf' => Icons.picture_as_pdf,
    'doc' || 'docx' => Icons.description,
    'xls' || 'xlsx' => Icons.table_chart,
    'ppt' || 'pptx' => Icons.slideshow,
    'zip' || 'rar' || '7z' || 'tar' => Icons.folder_zip,
    'apk' => Icons.android,
    'mp3' || 'flac' || 'aac' || 'wav' || 'm4a' => Icons.audio_file,
    'txt' || 'md' => Icons.text_snippet,
    _ => Icons.insert_drive_file,
  };
}

class _ServerThumb extends StatefulWidget {
  const _ServerThumb({
    required this.controller,
    required this.item,
    required this.isList,
  });

  final ServerBrowserController controller;
  final ServerFileItem item;
  final bool isList;

  @override
  State<_ServerThumb> createState() => _ServerThumbState();
}

class _ServerThumbState extends State<_ServerThumb> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Uint8List?> _load() async {
    return widget.controller.loadThumbnailWithRetry(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isList ? 48.0 : 84.0;
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              snapshot.data!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _ServerFileFallbackIcon(item: widget.item, size: size),
            ),
          );
        }
        return _ServerFileFallbackIcon(item: widget.item, size: size);
      },
    );
  }
}

class _ServerFileFallbackIcon extends StatelessWidget {
  const _ServerFileFallbackIcon({required this.item, required this.size});

  final ServerFileItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (item.isDir) {
      return Icon(Icons.folder, color: appAccent, size: size * 0.85);
    }
    return Icon(_iconForFile(item), color: appAccent, size: size * 0.8);
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({
    required this.controller,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final ServerBrowserController controller;
  final ServerFileItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey(item.path),
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ServerThumb(
                  controller: controller,
                  item: item,
                  isList: false,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
  const _ListItem({
    required this.controller,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onToggle,
    required this.onMenu,
  });

  final ServerBrowserController controller;
  final ServerFileItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggle;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey(item.path),
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _ServerThumb(controller: controller, item: item, isList: true),
        title: Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: controller.isSelectionMode
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

class _ServerHeaderControls extends StatelessWidget {
  const _ServerHeaderControls({
    required this.controller,
    required this.showCreateFolder,
    required this.onCreateFolder,
  });

  final ServerBrowserController controller;
  final bool showCreateFolder;
  final Future<void> Function() onCreateFolder;

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
                  child: DropdownButton<ServerSortBy>(
                    value: controller.sortBy,
                    dropdownColor: const Color(0xFF333333),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                    items: ServerSortBy.values
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
                        unawaited(controller.updateSortBy(v));
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
              onPressed: () => unawaited(controller.toggleSortDirection()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerFolderPickerScreen extends StatefulWidget {
  const _ServerFolderPickerScreen({
    required this.controller,
    required this.initialPath,
  });

  final ServerBrowserController controller;
  final String initialPath;

  @override
  State<_ServerFolderPickerScreen> createState() =>
      _ServerFolderPickerScreenState();
}

class _ServerFolderPickerScreenState extends State<_ServerFolderPickerScreen> {
  late List<String> _pathStack;
  List<ServerFileItem> _folders = const [];
  bool _loading = true;
  late ServerSortBy _sortBy;
  late bool _sortAscending;

  String get _currentPath => _pathStack.last;
  bool get _canGoUp => _pathStack.length > 1 || _currentPath.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pathStack = [widget.initialPath];
    _sortBy = widget.controller.sortBy;
    _sortAscending = widget.controller.sortAscending;
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final dirs = await widget.controller.listFoldersAt(_currentPath);
    final sorted = _sortFolders(dirs);
    if (!mounted) return;
    setState(() {
      _folders = sorted;
      _loading = false;
    });
  }

  List<ServerFileItem> _sortFolders(List<ServerFileItem> folders) {
    final sorted = List<ServerFileItem>.from(folders);
    final compare = switch (_sortBy) {
      ServerSortBy.name =>
        (ServerFileItem a, ServerFileItem b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ServerSortBy.date =>
        (ServerFileItem a, ServerFileItem b) =>
            a.modifiedAt.compareTo(b.modifiedAt),
      ServerSortBy.size =>
        (ServerFileItem a, ServerFileItem b) => a.size.compareTo(b.size),
      ServerSortBy.type =>
        (ServerFileItem a, ServerFileItem b) => a.type.compareTo(b.type),
    };
    sorted.sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
    return sorted;
  }

  void _applySorting() {
    setState(() {
      _folders = _sortFolders(_folders);
    });
  }

  String _parentPath(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '';
    segments.removeLast();
    return segments.join('/');
  }

  Future<void> _goUp() async {
    if (_pathStack.length > 1) {
      setState(() => _pathStack.removeLast());
      await _reload();
      return;
    }
    if (_currentPath.isEmpty) return;
    setState(() => _pathStack = [_parentPath(_currentPath)]);
    await _reload();
  }

  Future<void> _goToPath(String path) async {
    if (path == _currentPath) return;
    setState(() => _pathStack = [path]);
    await _reload();
  }

  List<({String label, String path})> _buildBreadcrumbItems() {
    final items = <({String label, String path})>[(label: 'root', path: '')];
    final segments = _currentPath.split('/').where((s) => s.isNotEmpty);
    var current = '';
    for (final segment in segments) {
      current = current.isEmpty ? segment : '$current/$segment';
      items.add((label: segment, path: current));
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
    await widget.controller.createFolderAtPath(_currentPath, name);
    if (!mounted) return;
    final msg = widget.controller.operationMessage ?? 'Folder created.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                        child: DropdownButton<ServerSortBy>(
                          value: _sortBy,
                          dropdownColor: const Color(0xFF333333),
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white70,
                          ),
                          items: ServerSortBy.values
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
                                d.name,
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

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.onDownload,
    required this.onDelete,
    required this.onShare,
    required this.onAddToFolder,
  });

  final Future<void> Function() onDownload;
  final Future<void> Function() onDelete;
  final Future<void> Function() onShare;
  final Future<void> Function() onAddToFolder;

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
        icon: Icons.download,
        label: 'Download',
        onPressed: onDownload,
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
