import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/trash_browser_controller.dart';
import 'package:crowleys_cloud/shared/viewers/image_viewer.dart';
import 'package:crowleys_cloud/shared/viewers/text_viewer.dart';
import 'package:crowleys_cloud/file_item.dart';

class TrashBrowserScreen extends StatefulWidget {
  const TrashBrowserScreen({
    super.key,
    required this.controller,
    required this.isGridView,
    required this.onToggleGridView,
  });

  final TrashBrowserController controller;
  final bool isGridView;
  final ValueChanged<bool> onToggleGridView;

  @override
  State<TrashBrowserScreen> createState() => _TrashBrowserScreenState();
}

class _TrashBrowserScreenState extends State<TrashBrowserScreen> {
  TrashBrowserController get controller => widget.controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.reload();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isPhoto(ServerFileItem item) {
    return photoExtensions.contains(p.extension(item.name).toLowerCase());
  }

  bool _isText(ServerFileItem item) {
    return textExtensions.contains(p.extension(item.name).toLowerCase());
  }

  Future<void> _handleTapItem(ServerFileItem item) async {
    if (controller.selectedFiles.isNotEmpty) {
      setState(() {
        controller.toggleSelection(item);
      });
      return;
    }

    if (item.isDir) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: appSurface,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: appAccent),
                SizedBox(width: 16),
                Text('Downloading file...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );

    File? temp;
    try {
      temp = await controller.downloadTempForEdit(item);
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context); // Dismiss loading dialog
    }

    if (temp == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download file preview')),
        );
      }
      return;
    }

    if (!mounted) return;

    if (_isPhoto(item)) {
      final photoServerItems = controller.files
          .where((entry) => !entry.isDir && _isPhoto(entry))
          .toList(growable: false);

      final tempToServerItem = <String, ServerFileItem>{};
      final imageItems = <FileItem>[];

      for (final photoItem in photoServerItems) {
        if (photoItem.id == item.id) {
          imageItems.add(FileItem.fromEntity(temp));
          tempToServerItem[temp.path] = photoItem;
        }
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewer(
            imageItems: imageItems,
            initialIndex: 0,
            onAddToFolderItem: (_) async {}, // Add to folder disabled in trash
          ),
        ),
      );
    } else if (_isText(item)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextViewer(file: temp!),
        ),
      );
    } else {
      await OpenFile.open(temp.path);
    }
  }

  void _showSingleItemMenu(ServerFileItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: appSurface,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.white70),
            title: const Text('Restore', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              setState(() {
                controller.selectedFiles.clear();
                controller.selectedFiles.add(item);
              });
              await _restoreSelected();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: appAccent),
            title: const Text('Delete permanently', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              setState(() {
                controller.selectedFiles.clear();
                controller.selectedFiles.add(item);
              });
              await _deleteSelected();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _restoreSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurface,
        title: const Text('Restore items', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to restore ${controller.selectedFiles.length} item(s)?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.restoreSelected();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurface,
        title: const Text('Permanently delete', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to permanently delete ${controller.selectedFiles.length} item(s)? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteSelected();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onSearchChanged(String val) {
    controller.updateSearchQuery(val);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = controller.selectedFiles.isNotEmpty;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: appSurface,
        surfaceTintColor: appSurface,
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    controller.clearSelection();
                  });
                },
              )
            : null,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: appBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white54, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search trash...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchController.clear();
                    });
                    controller.updateSearchQuery('');
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(widget.isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              widget.onToggleGridView(!widget.isGridView);
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            children: [
              Column(
                children: [
                  _TrashHeaderControls(controller: controller),
                  Expanded(child: _buildContent()),
                ],
              ),
              if (isSelectionMode)
                _TrashSelectionActionBar(
                  onRestore: _restoreSelected,
                  onDelete: _deleteSelected,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (controller.isLoading && controller.files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return Center(child: Text('Error: ${controller.error}', style: const TextStyle(color: Colors.redAccent)));
    }
    if (controller.files.isEmpty) {
      return const Center(child: Text('Trash is empty.', style: TextStyle(color: Colors.white70)));
    }

    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      thickness: 8,
      radius: const Radius.circular(4),
      child: widget.isGridView
          ? GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: controller.files.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, i) {
                final item = controller.files[i];
                final isSelected = controller.selectedFiles.contains(item);
                return _TrashGridItem(
                  controller: controller,
                  item: item,
                  isSelected: isSelected,
                  onTap: () => _handleTapItem(item),
                  onLongPress: () {
                    setState(() {
                      controller.toggleSelection(item);
                    });
                  },
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 80),
              itemCount: controller.files.length,
              itemBuilder: (context, i) {
                final item = controller.files[i];
                final isSelected = controller.selectedFiles.contains(item);
                return _TrashListItem(
                  controller: controller,
                  item: item,
                  isSelected: isSelected,
                  onTap: () => _handleTapItem(item),
                  onLongPress: () {
                    setState(() {
                      controller.toggleSelection(item);
                    });
                  },
                  onToggle: () {
                    setState(() {
                      controller.toggleSelection(item);
                    });
                  },
                  onMenu: () => _showSingleItemMenu(item),
                );
              },
            ),
    );
  }
}

class _TrashGridItem extends StatelessWidget {
  const _TrashGridItem({
    required this.controller,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final TrashBrowserController controller;
  final ServerFileItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey(item.id),
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TrashThumb(
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

class _TrashListItem extends StatelessWidget {
  const _TrashListItem({
    required this.controller,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onToggle,
    required this.onMenu,
  });

  final TrashBrowserController controller;
  final ServerFileItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggle;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey(item.id),
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tileColor: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.15) : appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected ? BorderSide(color: Theme.of(context).primaryColor, width: 1) : BorderSide.none,
        ),
        onTap: onTap,
        onLongPress: onLongPress,
        leading: _TrashThumb(
          controller: controller,
          item: item,
          isList: true,
        ),
        title: Text(
          item.name,
          style: const TextStyle(
            color: Colors.white70,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: controller.selectedFiles.isNotEmpty
            ? Checkbox(
                value: isSelected,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (_) => onToggle(),
              )
            : IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onPressed: onMenu,
              ),
      ),
    );
  }
}

class _TrashThumb extends StatefulWidget {
  const _TrashThumb({
    required this.controller,
    required this.item,
    required this.isList,
  });

  final TrashBrowserController controller;
  final ServerFileItem item;
  final bool isList;

  @override
  State<_TrashThumb> createState() => _TrashThumbState();
}

class _TrashThumbState extends State<_TrashThumb> {
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
    final size = widget.isList ? 48.0 : 120.0;
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              snapshot.data!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _TrashFileFallbackIcon(item: widget.item, size: size),
            ),
          );
        }
        return _TrashFileFallbackIcon(item: widget.item, size: size);
      },
    );
  }
}

class _TrashFileFallbackIcon extends StatelessWidget {
  const _TrashFileFallbackIcon({required this.item, required this.size});

  final ServerFileItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (item.isDir) {
      return Icon(Icons.folder, color: appAccent, size: size);
    }
    return Icon(_iconForFile(item), color: appAccent, size: size);
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
}

class _TrashHeaderControls extends StatelessWidget {
  const _TrashHeaderControls({
    required this.controller,
  });

  final TrashBrowserController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.selectedFiles.isNotEmpty) {
      final isAllSelected = controller.selectedFiles.length == controller.files.length && controller.files.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
        child: Row(
          children: [
            Checkbox(
              value: isAllSelected,
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
                  child: DropdownButton<TrashSortBy>(
                    value: controller.sortBy,
                    dropdownColor: const Color(0xFF333333),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                    items: TrashSortBy.values
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              v.name == 'date'
                                  ? 'Deletion Date'
                                  : v.name[0].toUpperCase() + v.name.substring(1),
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
              onPressed: () => controller.toggleSortDirection(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrashSelectionActionBar extends StatelessWidget {
  const _TrashSelectionActionBar({
    required this.onRestore,
    required this.onDelete,
  });

  final Future<void> Function() onRestore;
  final Future<void> Function() onDelete;

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Future<void> Function() onPressed,
    Color? color,
  }) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        minimumSize: const Size.fromHeight(48),
      ),
      icon: Icon(icon, color: color ?? Colors.white70),
      label: Text(
        label,
        style: TextStyle(color: color ?? Colors.white),
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
        icon: Icons.restore,
        label: 'Restore',
        onPressed: onRestore,
      ),
      _buildActionButton(
        icon: Icons.delete_forever,
        label: 'Delete permanently',
        color: appAccent,
        onPressed: onDelete,
      ),
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
                children: buttons.map((button) => Expanded(child: button)).toList(),
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
