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

import 'dart:async';
import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/shared/viewers/image_viewer.dart';
import 'package:crowleys_cloud/shared/viewers/text_viewer.dart';
import 'package:flutter/material.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:open_file/open_file.dart';

import 'package:crowleys_cloud/shared/utils/byte_formatter.dart';
import 'package:crowleys_cloud/shared/utils/file_icon_utils.dart';
import 'package:crowleys_cloud/shared/widgets/breadcrumb_bar.dart';
import 'package:crowleys_cloud/shared/widgets/create_folder_dialog.dart';
import 'package:crowleys_cloud/shared/widgets/remote_thumbnail_widget.dart';
import 'package:crowleys_cloud/shared/widgets/selection_action_bar.dart';
import 'package:crowleys_cloud/shared/widgets/selection_header_bar.dart';
import 'package:crowleys_cloud/smart_thumbnail.dart';

/// ServerFileBrowser renders remote server files and folders in grid or list view.
///
/// Performance optimizations:
/// - Employs [ListenableBuilder] to localize rebuilds to header controls, breadcrumbs, content, or action bar.
/// - Uses state-memoized [_ServerThumb] widgets to eliminate repeated future creation during list scrolling.
/// - Leverages unified [CacheService] RAM + disk caching for remote thumbnails.
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
    await _openFile(item);
  }

  Future<void> _openFile(ServerFileItem item) async {
    if (_isPhoto(item)) {
      await _openImageViewer(item);
    } else if (_isText(item)) {
      await _openTextViewer(item);
    } else {
      final temp = await controller.downloadTempForEdit(item);
      if (temp != null) {
        await OpenFile.open(temp.path);
      }
    }
  }

  bool _isPhoto(ServerFileItem item) {
    return item.type == 'photo' || photoExtensions.contains(item.extension);
  }

  bool _isText(ServerFileItem item) {
    if (textExtensions.contains(item.extension)) return true;
    return item.mimeType.startsWith('text/');
  }

  Future<void> _openImageViewer(ServerFileItem item) async {
    final photoServerItems = controller.files
        .where((entry) => !entry.isDir && _isPhoto(entry))
        .toList(growable: false);
    if (photoServerItems.isEmpty) return;

    final imageItems = photoServerItems.map(FileItem.fromServer).toList();
    var initialIndex = imageItems.indexWhere(
      (imageItem) => imageItem.serverFile?.path == item.path,
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
            controller.clearSelection();
            controller.toggleSelection(selectedServerItem);
            await controller.deleteSelectedFiles();
            _showOperationMessage();
          },
          onRenameItem: (selectedImageItem) async {
            final selectedServerItem = selectedImageItem.serverFile;
            if (selectedServerItem == null) return;
            await _renameItem(selectedServerItem);
          },
          onAddToFolderItem: (selectedImageItem) async {
            final selectedServerItem = selectedImageItem.serverFile;
            if (selectedServerItem == null) return;
            controller.clearSelection();
            controller.toggleSelection(selectedServerItem);
            await _addSelectedToFolder();
          },
          onShareItem: (selectedImageItem) async {
            final selectedServerItem = selectedImageItem.serverFile;
            if (selectedServerItem == null) return;
            controller.clearSelection();
            controller.toggleSelection(selectedServerItem);
            if (controller.scope == 'shared') {
              await _shareSelectedFiles();
            } else {
              await _showShareOptions();
            }
          },
        ),
      ),
    );
  }

  Future<void> _openTextViewer(ServerFileItem item) async {
    final temp = await controller.downloadTempForEdit(item);
    if (temp == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextViewer(file: File(temp.path)),
      ),
    );
  }

  Future<void> _deleteSelectedFiles() async {
    final selectedCount = controller.selectedFiles.length;
    if (selectedCount == 0) return;
    final isSharedScope = controller.scope == 'shared';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: appSurface,
          title: Text(
            isSharedScope ? l10n.unshareItemsTitle : l10n.deleteFilesTitle,
            style: TextStyle(color: appText),
          ),
          content: Text(
            isSharedScope
                ? l10n.unshareItemsBody(selectedCount)
                : l10n.deleteFilesBody(selectedCount),
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
                isSharedScope ? l10n.unshare : l10n.delete,
                style: TextStyle(
                  color: isSharedScope ? appAccent : Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
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
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.link, color: appSubtext),
              title: Text(l10n.shareViaLink, style: TextStyle(color: appText)),
              onTap: () async {
                Navigator.pop(context);
                await _shareSelectedFiles();
              },
            ),
            ListTile(
              leading: Icon(Icons.folder_shared, color: appSubtext),
              title: Text(l10n.shareInServer, style: TextStyle(color: appText)),
              onTap: () async {
                Navigator.pop(context);
                await _shareSelectedInServer();
              },
            ),
          ],
        );
      },
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

  Future<void> _renameItem(ServerFileItem item) async {
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
    await controller.renameItem(item, newName);
    _showOperationMessage();
  }

  void _showContextMenu(BuildContext context, ServerFileItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appSurface,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return Wrap(
          children: [
            if (controller.scope != 'shared')
              ListTile(
                leading: Icon(Icons.edit, color: appSubtext),
                title: Text(l10n.rename, style: TextStyle(color: appText)),
                onTap: () async {
                  Navigator.pop(context);
                  await _renameItem(item);
                },
              ),
            ListTile(
              leading: Icon(Icons.download, color: appSubtext),
              title: Text(l10n.download, style: TextStyle(color: appText)),
              onTap: () async {
                Navigator.pop(context);
                controller.toggleSelection(item);
                await _downloadSelectedFiles();
              },
            ),
            ListTile(
              leading: Icon(
                controller.scope == 'shared' ? Icons.link_off : Icons.delete,
                color: appSubtext,
              ),
              title: Text(
                controller.scope == 'shared' ? l10n.unshare : l10n.delete,
                style: TextStyle(color: appText),
              ),
              onTap: () async {
                Navigator.pop(context);
                controller.toggleSelection(item);
                await _deleteSelectedFiles();
              },
            ),
            if (controller.scope != 'shared') ...[
              ListTile(
                leading: Icon(Icons.share, color: appSubtext),
                title: Text(
                  l10n.shareViaLink,
                  style: TextStyle(color: appText),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  controller.toggleSelection(item);
                  await _shareSelectedFiles();
                },
              ),
              ListTile(
                leading: Icon(Icons.folder_shared, color: appSubtext),
                title: Text(
                  l10n.shareInServer,
                  style: TextStyle(color: appText),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  controller.toggleSelection(item);
                  await _shareSelectedInServer();
                },
              ),
              ListTile(
                leading: Icon(Icons.drive_file_move, color: appSubtext),
                title: Text(l10n.addToFolder, style: TextStyle(color: appText)),
                onTap: () async {
                  Navigator.pop(context);
                  controller.toggleSelection(item);
                  await _addSelectedToFolder();
                },
              ),
            ],
          ],
        );
      },
    );
  }

  List<({String label, String path})> _buildMainBreadcrumbItems(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final items = <({String label, String path})>[
      (label: l10n.serverRoot, path: ''),
    ];
    final segments = controller.currentPath
        .split('/')
        .where((s) => s.isNotEmpty);
    var path = '';
    for (final segment in segments) {
      path = path.isEmpty ? segment : '$path/$segment';
      items.add((label: segment, path: path));
    }
    return items;
  }

  Widget _buildMainBreadcrumb(BuildContext context) {
    if (controller.selectedType != 'all' || controller.isSelectionMode) {
      return const SizedBox.shrink();
    }
    return BreadcrumbBar(
      items: _buildMainBreadcrumbItems(context),
      onItemTap: controller.navigateToPath,
      backgroundColor: appSurface,
      textColor: appSubtext,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _ServerHeaderControls(
                controller: controller,
                showCreateFolder: controller.selectedType == 'all',
                onCreateFolder: _createFolder,
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _buildMainBreadcrumb(context),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => _buildContent(context),
              ),
            ),
          ],
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (!controller.isSelectionMode) return const SizedBox.shrink();
            return _SelectionActionBar(
              onDownload: _downloadSelectedFiles,
              onDelete: _deleteSelectedFiles,
              onShare: controller.scope == 'shared'
                  ? _shareSelectedFiles
                  : _showShareOptions,
              onAddToFolder: _addSelectedToFolder,
              onRename: controller.selectedFiles.length == 1
                  ? () => _renameItem(controller.selectedFiles.first)
                  : null,
              scope: controller.scope,
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (controller.isLoading && controller.files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return Center(child: Text(l10n.errorWithMessage(controller.error ?? '')));
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

IconData _iconForFile(ServerFileItem item) =>
    FileIconUtils.iconForExtension(item.extension);

/// Dedicated thumbnail widget for server file items.
/// Memoizes [Future] in state to prevent redundant network/cache fetches on scroll frames.
class _ServerThumb extends StatelessWidget {
  const _ServerThumb({
    required this.controller,
    required this.item,
    required this.isList,
  });

  final ServerBrowserController controller;
  final ServerFileItem item;
  final bool isList;

  @override
  Widget build(BuildContext context) {
    return RemoteThumbnailWidget(
      thumbnailLoader: () => controller.loadThumbnailWithRetry(item),
      fallbackBuilder: (context, size) =>
          _ServerFileFallbackIcon(item: item, size: size),
      isList: isList,
      cacheKey: '${item.path}_${item.modifiedAt}',
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
      return Icon(Icons.folder, color: appAccent, size: size);
    }
    return Icon(_iconForFile(item), color: appAccent, size: size);
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
    final l10n = AppLocalizations.of(context)!;
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
                style: TextStyle(color: appText),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (controller.scope == 'shared' &&
                  (item.ownerName != null || item.uploaderUserId != null)) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 11, color: appAccent),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        item.ownerName ??
                            l10n.userFallback(item.uploaderUserId ?? 0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: appAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
    final l10n = AppLocalizations.of(context)!;
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
          style: TextStyle(color: appText),
        ),
        subtitle:
            (controller.scope == 'shared' &&
                (item.ownerName != null || item.uploaderUserId != null))
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 13, color: appAccent),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.ownerName ??
                            l10n.userFallback(item.uploaderUserId ?? 0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: appAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: controller.isSelectionMode
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Row(
        children: [
          if (showCreateFolder)
            FilledButton.icon(
              onPressed: onCreateFolder,
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
                  child: DropdownButton<ServerSortBy>(
                    value: controller.sortBy,
                    dropdownColor: appSurface,
                    style: TextStyle(color: appText),
                    icon: Icon(Icons.arrow_drop_down, color: appSubtext),
                    items: ServerSortBy.values
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              switch (v) {
                                ServerSortBy.name => l10n.name,
                                ServerSortBy.date => l10n.date,
                                ServerSortBy.size => l10n.size,
                                ServerSortBy.type => l10n.type,
                              },
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
                color: appSubtext,
              ),
              onPressed: () => unawaited(controller.toggleSortDirection()),
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
              icon: Icon(Icons.bar_chart_rounded, color: appSubtext),
              tooltip: l10n.storageStatsTitle,
              onPressed: () => _showStatsBottomSheet(context, controller),
            ),
          ),
        ],
      ),
    );
  }
}

void _showStatsBottomSheet(
  BuildContext context,
  ServerBrowserController controller,
) {
  if (controller.accountStats == null) {
    unawaited(controller.fetchAccountStats());
  }
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: appSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final stats = controller.accountStats;
          if (stats == null) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final totalSize = (stats['total_size'] as num?)?.toInt() ?? 0;
          final totalCount = (stats['total_count'] as num?)?.toInt() ?? 0;

          final categories = [
            (
              label: l10n.categoryPhotos,
              icon: Icons.image,
              count: (stats['photo_count'] as num?)?.toInt() ?? 0,
              size: (stats['photo_size'] as num?)?.toInt() ?? 0,
            ),
            (
              label: l10n.categoryVideos,
              icon: Icons.movie,
              count: (stats['video_count'] as num?)?.toInt() ?? 0,
              size: (stats['video_size'] as num?)?.toInt() ?? 0,
            ),
            (
              label: l10n.categoryAudio,
              icon: Icons.audiotrack,
              count: (stats['audio_count'] as num?)?.toInt() ?? 0,
              size: (stats['audio_size'] as num?)?.toInt() ?? 0,
            ),
            (
              label: l10n.categoryDocuments,
              icon: Icons.description,
              count: (stats['document_count'] as num?)?.toInt() ?? 0,
              size: (stats['document_size'] as num?)?.toInt() ?? 0,
            ),
            (
              label: l10n.categoryShared,
              icon: Icons.group,
              count: (stats['shared_count'] as num?)?.toInt() ?? 0,
              size: (stats['shared_size'] as num?)?.toInt() ?? 0,
            ),
            (
              label: l10n.categoryOther,
              icon: Icons.category,
              count: (stats['other_count'] as num?)?.toInt() ?? 0,
              size: (stats['other_size'] as num?)?.toInt() ?? 0,
            ),
          ];

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_queue, color: appAccent, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        l10n.storageStatsTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: appText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: appSubtext),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: appAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.storageStatsUsedSpace,
                              style: TextStyle(fontSize: 12, color: appSubtext),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ByteFormatter.format(totalSize),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: appAccent,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.storageStatsTotalFiles,
                              style: TextStyle(fontSize: 12, color: appSubtext),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.storageStatsNItems(totalCount),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: appText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 2.2,
                            ),
                        itemBuilder: (context, i) {
                          final c = categories[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(c.icon, size: 20, color: appAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        c.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: appText,
                                        ),
                                      ),
                                      Text(
                                        '${c.count} • ${ByteFormatter.format(c.size)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: appSubtext,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
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

  List<({String label, String path})> _buildBreadcrumbItems(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final items = <({String label, String path})>[
      (label: l10n.serverRoot, path: ''),
    ];
    final segments = _currentPath.split('/').where((s) => s.isNotEmpty);
    var current = '';
    for (final segment in segments) {
      current = current.isEmpty ? segment : '$current/$segment';
      items.add((label: segment, path: current));
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
    await widget.controller.createFolderAtPath(_currentPath, name);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final msg = widget.controller.operationMessage ?? l10n.folderCreated;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                        child: DropdownButton<ServerSortBy>(
                          value: _sortBy,
                          dropdownColor: appSurface,
                          style: TextStyle(color: appText),
                          icon: Icon(Icons.arrow_drop_down, color: appSubtext),
                          items: ServerSortBy.values
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    switch (v) {
                                      ServerSortBy.name => l10n.name,
                                      ServerSortBy.date => l10n.date,
                                      ServerSortBy.size => l10n.size,
                                      ServerSortBy.type => l10n.type,
                                    },
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
                                d.name,
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

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.onDownload,
    required this.onDelete,
    required this.onShare,
    required this.onAddToFolder,
    this.onRename,
    this.scope = 'private',
  });

  final Future<void> Function() onDownload;
  final Future<void> Function() onDelete;
  final Future<void> Function() onShare;
  final Future<void> Function() onAddToFolder;
  final Future<void> Function()? onRename;
  final String scope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SelectionActionBar(
      backgroundColor: appSurface,
      textColor: appText,
      iconColor: appSubtext,
      actions: [
        if (onRename != null && scope != 'shared')
          SelectionAction(
            icon: Icons.edit,
            label: l10n.rename,
            onPressed: onRename!,
          ),
        SelectionAction(
          icon: Icons.download,
          label: l10n.download,
          onPressed: onDownload,
        ),
        SelectionAction(
          icon: scope == 'shared' ? Icons.link_off : Icons.delete,
          label: scope == 'shared' ? l10n.unshare : l10n.delete,
          onPressed: onDelete,
        ),
        if (scope != 'shared') ...[
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
      ],
    );
  }
}
