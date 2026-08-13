import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/trash_browser_controller.dart';
import 'package:crowleys_cloud/shared/viewers/image_viewer.dart';
import 'package:crowleys_cloud/shared/viewers/text_viewer.dart';
import 'package:crowleys_cloud/file_item.dart';

import 'package:crowleys_cloud/shared/utils/file_icon_utils.dart';
import 'package:crowleys_cloud/shared/widgets/remote_thumbnail_widget.dart';
import 'package:crowleys_cloud/shared/widgets/selection_action_bar.dart';
import 'package:crowleys_cloud/shared/widgets/selection_header_bar.dart';
import 'package:crowleys_cloud/smart_thumbnail.dart';

/// TrashBrowserScreen displays files in the server trash bin for restoration or permanent deletion.
///
/// Performance optimizations:
/// - Replaced top-level controller listener rebuilds with scoped [ListenableBuilder] widgets.
/// - Uses state-memoized [_TrashThumb] widgets to prevent future re-instantiation during scroll frames.
/// - Leverages unified [CacheService] RAM + disk caching for remote thumbnail bytes.
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
  final FocusNode _searchFocusNode = FocusNode();
  late bool _isGridView;

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _isGridView = widget.isGridView;
    controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.reload();
    });
  }

  @override
  void didUpdateWidget(TrashBrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (oldWidget.isGridView != widget.isGridView) {
      _isGridView = widget.isGridView;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
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

    if (_isPhoto(item)) {
      await _openImageViewer(item);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          color: appSurface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: appAccent),
                const SizedBox(width: 16),
                const Text(
                  'Downloading file...',
                  style: TextStyle(color: Colors.white),
                ),
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

    if (_isText(item)) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TextViewer(file: temp!)),
      );
    } else {
      await OpenFile.open(temp.path);
    }
  }

  Future<void> _openImageViewer(ServerFileItem item) async {
    final photoServerItems = controller.files
        .where((entry) => !entry.isDir && _isPhoto(entry))
        .toList(growable: false);
    if (photoServerItems.isEmpty) return;

    final imageItems = photoServerItems.map(FileItem.fromServer).toList();
    var initialIndex = imageItems.indexWhere(
      (imageItem) => imageItem.serverFile?.id == item.id,
    );
    if (initialIndex < 0) initialIndex = 0;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          imageItems: imageItems,
          initialIndex: initialIndex,
          onFetchRemoteFile: (fileItem) async {
            final serverItem = fileItem.serverFile;
            if (serverItem == null) return null;
            return controller.downloadTempForEdit(serverItem);
          },
          thumbnailPlaceholderBuilder: (fileItem) {
            return SizedBox(
              width: 150,
              height: 150,
              child: SmartThumbnail(item: fileItem),
            );
          },
          onDeleteItem: (selectedImageItem) async {
            final selectedServerItem = selectedImageItem.serverFile;
            if (selectedServerItem == null) return;
            controller.selectedFiles.clear();
            controller.selectedFiles.add(selectedServerItem);
            await controller.deleteSelected();
          },
        ),
      ),
    );
  }

  void _showSingleItemMenu(ServerFileItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: appSurface,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.restore, color: appSubtext),
            title: Text('Restore', style: TextStyle(color: appText)),
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
            leading: Icon(Icons.delete_forever, color: appAccent),
            title: Text('Delete permanently', style: TextStyle(color: appText)),
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
        title: Text('Restore items', style: TextStyle(color: appText)),
        content: Text(
          'Are you sure you want to restore ${controller.selectedFiles.length} item(s)?',
          style: TextStyle(color: appSubtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: appSubtext)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Restore', style: TextStyle(color: appText)),
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
        title: Text('Permanently delete', style: TextStyle(color: appText)),
        content: Text(
          'Are you sure you want to permanently delete ${controller.selectedFiles.length} item(s)? This action cannot be undone.',
          style: TextStyle(color: appSubtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: appSubtext)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete permanently', style: TextStyle(color: appText)),
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

    return PopScope(
      canPop: !isSelectionMode && !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return;
        }
        if (isSelectionMode) {
          controller.clearSelection();
        }
      },
      child: Scaffold(
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
                Icon(Icons.search, color: appSubtext, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search trash...',
                      hintStyle: TextStyle(color: appSubtext),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(color: appText),
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
                    child: Icon(Icons.close, color: appSubtext, size: 20),
                  ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
                widget.onToggleGridView(_isGridView);
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) =>
                      _TrashHeaderControls(controller: controller),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => _buildContent(),
                  ),
                ),
              ],
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.selectedFiles.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _TrashSelectionActionBar(
                  onRestore: _restoreSelected,
                  onDelete: _deleteSelected,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (controller.isLoading && controller.files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return Center(
        child: Text(
          'Error: ${controller.error}',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }
    if (controller.files.isEmpty) {
      return Center(
        child: Text('Trash is empty.', style: TextStyle(color: appSubtext)),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      thickness: 8,
      radius: const Radius.circular(4),
      child: _isGridView
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
                style: TextStyle(color: appText),
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
        tileColor: isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
            : appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 1)
              : BorderSide.none,
        ),
        onTap: onTap,
        onLongPress: onLongPress,
        leading: _TrashThumb(controller: controller, item: item, isList: true),
        title: Text(
          item.name,
          style: TextStyle(color: appText),
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
                icon: Icon(Icons.more_vert, color: appSubtext),
                onPressed: onMenu,
              ),
      ),
    );
  }
}

/// Dedicated thumbnail widget for trash item previews.
/// Memoizes [Future] in state to prevent redundant network/cache fetches on scroll frames.
class _TrashThumb extends StatelessWidget {
  const _TrashThumb({
    required this.controller,
    required this.item,
    required this.isList,
  });

  final TrashBrowserController controller;
  final ServerFileItem item;
  final bool isList;

  @override
  Widget build(BuildContext context) {
    return RemoteThumbnailWidget(
      thumbnailLoader: () => controller.loadThumbnailWithRetry(item),
      fallbackBuilder: (context, size) =>
          _TrashFileFallbackIcon(item: item, size: size),
      isList: isList,
      cacheKey: '${item.path}_${item.modifiedAt}',
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
    return Icon(
      FileIconUtils.iconForExtension(item.extension),
      color: appAccent,
      size: size,
    );
  }
}

class _TrashHeaderControls extends StatelessWidget {
  const _TrashHeaderControls({required this.controller});

  final TrashBrowserController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.selectedFiles.isNotEmpty) {
      return SelectionHeaderBar(
        selectedCount: controller.selectedFiles.length,
        totalCount: controller.files.length,
        onSelectAll: controller.selectAll,
        onClearSelection: controller.clearSelection,
        textColor: appSubtext,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: appSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: appSubtext.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: appSubtext),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Items in trash are automatically deleted after ${controller.trashRetentionDays} days.',
                  style: TextStyle(
                    color: appSubtext,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
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
                Icon(Icons.sort, color: appSubtext, size: 20),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<TrashSortBy>(
                    value: controller.sortBy,
                    dropdownColor: appSurface,
                    style: TextStyle(color: appText),
                    icon: Icon(Icons.arrow_drop_down, color: appSubtext),
                    items: TrashSortBy.values
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              v.name == 'date'
                                  ? 'Deletion Date'
                                  : v.name[0].toUpperCase() +
                                        v.name.substring(1),
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
                color: appSubtext,
              ),
              onPressed: () => controller.toggleSortDirection(),
            ),
          ),
        ],
      ),
    ),
  ],
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

  @override
  Widget build(BuildContext context) {
    return SelectionActionBar(
      backgroundColor: appSurface,
      textColor: appText,
      iconColor: appSubtext,
      actions: [
        SelectionAction(
          icon: Icons.restore,
          label: 'Restore',
          onPressed: onRestore,
        ),
        SelectionAction(
          icon: Icons.delete_forever,
          label: 'Delete Permanently',
          onPressed: onDelete,
          color: Colors.red.shade400,
        ),
      ],
    );
  }
}
