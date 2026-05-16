import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/shared/viewers/image_viewer.dart';
import 'package:crowleys_cloud/shared/viewers/text_viewer.dart';
import 'package:crowleys_cloud/smart_thumbnail.dart';
import 'package:flutter/material.dart';

class FileBrowser extends StatefulWidget {
  final FileCategory category;
  final bool isGridView;
  final FileBrowserController? controller;

  const FileBrowser({
    super.key,
    required this.category,
    required this.isGridView,
    this.controller,
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

  void _showContextMenu(BuildContext context, FileItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appSurface,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.upload, color: Colors.white70),
            title: const Text('Upload', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
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
                _HeaderControls(controller: _controller),
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
                onDelete: _deleteSelectedFiles,
                onShare: _controller.shareSelectedFiles,
              ),
          ],
        );
      },
    );
  }
}

class _HeaderControls extends StatelessWidget {
  final FileBrowserController controller;

  const _HeaderControls({required this.controller});

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
      padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
  final Future<void> Function() onDelete;
  final Future<void> Function() onShare;

  const _SelectionActionBar({required this.onDelete, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: appBackground,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.upload, color: Colors.white70),
                label: const Text(
                  'Upload',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {},
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.white70),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: onDelete,
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.share, color: Colors.white70),
                label: const Text(
                  'Share',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: onShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
