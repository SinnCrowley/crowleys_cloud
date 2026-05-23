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
    }
  }

  Future<void> _downloadSelectedFiles() async {
    await controller.downloadSelectedFiles();
  }

  Future<void> _shareSelectedFiles() async {
    await controller.shareSelectedFiles();
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
            title: const Text('Share', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              controller.toggleSelection(item);
              await _shareSelectedFiles();
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
        if (controller.isLoading && controller.files.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error != null) {
          return Center(child: Text('Error: ${controller.error}'));
        }
        if (controller.files.isEmpty) {
          return const Center(child: Text('No files found.'));
        }

        return Stack(
          children: [
            Column(
              children: [
                _ServerHeaderControls(controller: controller),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    interactive: true,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: controller.files.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
                              onLongPress: () => controller.toggleSelection(
                                controller.files[i],
                              ),
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
                                isSelected: controller.selectedFiles.contains(
                                  item,
                                ),
                                onTap: () => _onTapItem(item),
                                onLongPress: () =>
                                    controller.toggleSelection(item),
                                onToggle: () =>
                                    controller.toggleSelection(item),
                                onMenu: () => _showContextMenu(context, item),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
            if (controller.isSelectionMode)
              _SelectionActionBar(
                onDownload: _downloadSelectedFiles,
                onDelete: _deleteSelectedFiles,
                onShare: _shareSelectedFiles,
              ),
          ],
        );
      },
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
  const _ServerHeaderControls({required this.controller});

  final ServerBrowserController controller;

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

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.onDownload,
    required this.onDelete,
    required this.onShare,
  });

  final Future<void> Function() onDownload;
  final Future<void> Function() onDelete;
  final Future<void> Function() onShare;

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
                icon: const Icon(Icons.download, color: Colors.white70),
                label: const Text(
                  'Download',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: onDownload,
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
