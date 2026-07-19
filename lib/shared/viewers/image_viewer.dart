import 'dart:async';
import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewer extends StatefulWidget {
  final List<FileItem> imageItems;
  final int initialIndex;
  final Future<void> Function(FileItem item)? onUploadItem;
  final Future<void> Function(FileItem item)? onDeleteItem;
  final Future<void> Function(FileItem item)? onAddToFolderItem;
  final Future<File?> Function(FileItem item)? onFetchRemoteFile;
  final Widget Function(FileItem item)? thumbnailPlaceholderBuilder;

  const ImageViewer({
    super.key,
    required this.imageItems,
    required this.initialIndex,
    this.onUploadItem,
    this.onDeleteItem,
    this.onAddToFolderItem,
    this.onFetchRemoteFile,
    this.thumbnailPlaceholderBuilder,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late List<FileItem> _items;
  bool _isUiVisible = true;
  int _pointerCount = 0;
  double _dragOffset = 0.0;
  bool _isDraggingUp = false;

  @override
  void initState() {
    super.initState();
    _items = List<FileItem>.from(widget.imageItems);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages(_currentIndex);
  }

  void _precacheImages(int index) {
    for (int i = index - 1; i <= index + 1; i++) {
      if (i >= 0 && i < _items.length) {
        final item = _items[i];
        if (item.isAsset) {
          precacheImage(
            AssetEntityImageProvider(
              item.asset!,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(1280),
            ),
            context,
          );
        } else if (item.isRemote) {
          if (widget.onFetchRemoteFile != null) {
            unawaited(widget.onFetchRemoteFile!(item));
          }
        } else {
          precacheImage(FileImage(File(item.pathSync)), context);
        }
      }
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_pointerCount > 1) return;
    setState(() {
      _dragOffset += details.delta.dy;
      _isDraggingUp = _dragOffset < 0;
    });
    if (_isDraggingUp && _isUiVisible) {
      setState(() => _isUiVisible = false);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if ((_dragOffset < -150 || velocity < -800) && _isDraggingUp) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
        _isDraggingUp = false;
        _isUiVisible = true;
      });
    }
  }

  Future<void> _shareCurrentFile() async {
    if (_currentIndex < 0 || _currentIndex >= _items.length) return;
    final path = await _items[_currentIndex].path;
    if (path.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    }
  }

  Future<void> _deleteCurrentFile() async {
    if (_currentIndex < 0 || _currentIndex >= _items.length) return;
    final item = _items[_currentIndex];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurface,
        title: Text(
          'Delete File?',
          style: TextStyle(color: appText),
        ),
        content: Text(
          'Are you sure you want to delete ${item.name}? This action cannot be undone.',
          style: TextStyle(color: appSubtext),
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
      try {
        if (widget.onDeleteItem != null) {
          await widget.onDeleteItem!(item);
        } else if (item.isAsset) {
          final file = await item.asset!.originFile;
          if (file != null) await file.delete();
        } else if (item.fsEntity != null) {
          await item.fsEntity!.delete();
        }

        _items.removeAt(_currentIndex);
        if (_items.isEmpty) {
          if (mounted) Navigator.of(context).pop(true);
        } else {
          if (_currentIndex >= _items.length) {
            _currentIndex = _items.length - 1;
          }
          if (mounted) {
            _pageController.jumpToPage(_currentIndex);
            setState(() {});
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting ${item.name}: $e')),
          );
        }
      }
    }
  }

  Future<void> _uploadCurrentFile() async {
    final callback = widget.onUploadItem;
    if (callback == null || _currentIndex < 0 || _currentIndex >= _items.length) return;
    await callback(_items[_currentIndex]);
  }

  Future<void> _addCurrentFileToFolder() async {
    final callback = widget.onAddToFolderItem;
    if (callback == null || _currentIndex < 0 || _currentIndex >= _items.length) return;
    await callback(_items[_currentIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (_) => setState(() => _pointerCount++),
        onPointerUp: (_) => setState(() => _pointerCount--),
        onPointerCancel: (_) => setState(() => _pointerCount--),
        child: GestureDetector(
          onTap: () {
            if (!_isDraggingUp) setState(() => _isUiVisible = !_isUiVisible);
          },
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(0, _dragOffset),
                child: Opacity(
                  opacity: (_isDraggingUp
                      ? (1 + _dragOffset / 400).clamp(0.0, 1.0)
                      : 1.0),
                  child: PageView.builder(
                    controller: _pageController,
                    physics: _pointerCount > 1 || _isDraggingUp
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    itemCount: _items.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      _precacheImages(index);
                    },
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return InteractiveViewer(
                        panEnabled: !_isDraggingUp,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Hero(
                            tag: item.pathSync,
                            child: item.isAsset
                                ? AssetEntityImage(
                                    item.asset!,
                                    isOriginal: false,
                                    thumbnailSize: const ThumbnailSize.square(
                                      1280,
                                    ),
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  )
                                : item.isRemote
                                ? _RemoteImageView(
                                    item: item,
                                    onFetch: widget.onFetchRemoteFile,
                                    placeholder: widget
                                        .thumbnailPlaceholderBuilder
                                        ?.call(item),
                                  )
                                : Image.file(
                                    File(item.pathSync),
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                top: (_isUiVisible && !_isDraggingUp) ? 0 : -140,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                  ),
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          _currentIndex >= 0 && _currentIndex < _items.length
                              ? _items[_currentIndex].name
                              : '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                bottom: (_isUiVisible && !_isDraggingUp) ? 0 : -160,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: Icons.upload,
                        label: 'Upload',
                        onPressed: _uploadCurrentFile,
                      ),
                      _ActionButton(
                        icon: Icons.delete,
                        label: 'Delete',
                        onPressed: _deleteCurrentFile,
                      ),
                      _ActionButton(
                        icon: Icons.drive_file_move,
                        label: 'Add to folder',
                        onPressed: _addCurrentFileToFolder,
                        enabled: widget.onAddToFolderItem != null,
                      ),
                      _ActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onPressed: _shareCurrentFile,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isDraggingUp)
                Positioned.fill(
                  child: Opacity(
                    opacity: (_dragOffset.abs() / 600).clamp(0.0, 0.6),
                    child: Container(color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: enabled ? Colors.white70 : Colors.white24,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoteImageView extends StatefulWidget {
  final FileItem item;
  final Future<File?> Function(FileItem item)? onFetch;
  final Widget? placeholder;

  const _RemoteImageView({
    required this.item,
    required this.onFetch,
    this.placeholder,
  });

  @override
  State<_RemoteImageView> createState() => _RemoteImageViewState();
}

class _RemoteImageViewState extends State<_RemoteImageView> {
  File? _file;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _RemoteImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _load();
    }
  }

  Future<void> _load() async {
    final existingPath = widget.item.pathSync;
    if (existingPath.isNotEmpty && existingPath.startsWith('/')) {
      final existingFile = File(existingPath);
      if (await existingFile.exists()) {
        if (mounted) {
          setState(() {
            _file = existingFile;
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (widget.onFetch == null) {
      if (mounted) {
        setState(() {
          _error = "No fetch handler configured";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final file = await widget.onFetch!(widget.item);
      if (file != null) {
        widget.item.cachedPath = file.path;
      }
      if (mounted) {
        setState(() {
          _file = file;
          _isLoading = false;
          if (file == null) {
            _error = "Failed to load image";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_file != null) {
      return Image.file(_file!, fit: BoxFit.contain, gaplessPlayback: true);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.placeholder != null) widget.placeholder!,
        if (_isLoading)
          const CircularProgressIndicator(color: Colors.white)
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      ],
    );
  }
}
