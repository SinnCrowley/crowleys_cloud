import 'dart:async';
import 'dart:typed_data';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class ServerFileBrowser extends StatelessWidget {
  const ServerFileBrowser({
    super.key,
    required this.controller,
    required this.isGridView,
  });

  final ServerBrowserController controller;
  final bool isGridView;

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

        return Column(
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
                        itemBuilder: (context, i) =>
                            _gridItem(context, controller.files[i]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.files.length,
                        itemBuilder: (context, i) =>
                            _listItem(context, controller.files[i]),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _gridItem(BuildContext context, ServerFileItem item) {
    return InkWell(
      key: ValueKey(item.path),
      onTap: () => _onTapItem(item),
      borderRadius: BorderRadius.circular(12),
      child: Column(
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
    );
  }

  Widget _listItem(BuildContext context, ServerFileItem item) {
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
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () => _onTapItem(item),
        tileColor: appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _onTapItem(ServerFileItem item) async {
    if (item.isDir) {
      await controller.navigateInto(item);
      return;
    }

    // Always open from a downloaded temp file; URL opening is unreliable
    // with OpenFile on many platforms.
    final temp = await controller.downloadTempForEdit(item);
    if (temp != null) {
      await OpenFile.open(temp.path);
    }
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
              errorBuilder: (_, _, _) => _ServerFileFallbackIcon(
                item: widget.item,
                size: size,
              ),
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

class _ServerHeaderControls extends StatelessWidget {
  const _ServerHeaderControls({required this.controller});

  final ServerBrowserController controller;

  @override
  Widget build(BuildContext context) {
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
