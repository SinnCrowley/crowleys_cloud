import 'dart:io';

import 'package:crowleys_cloud/file_item.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewer extends StatefulWidget {
  final List<FileItem> imageItems;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.imageItems,
    required this.initialIndex,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _isUiVisible = true;
  int _pointerCount = 0;
  double _dragOffset = 0.0;
  bool _isDraggingUp = false;

  @override
  void initState() {
    super.initState();
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
      if (i >= 0 && i < widget.imageItems.length) {
        final item = widget.imageItems[i];
        if (item.isAsset) {
          precacheImage(
            AssetEntityImageProvider(
              item.asset!,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(1280),
            ),
            context,
          );
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
    final path = await widget.imageItems[_currentIndex].path;
    if (path.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    }
  }

  Future<void> _deleteCurrentFile() async {
    final item = widget.imageItems[_currentIndex];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Delete File?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${item.name}? This action cannot be undone.',
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
      try {
        if (item.isAsset) {
          final file = await item.asset!.originFile;
          if (file != null) await file.delete();
        } else if (item.fsEntity != null) {
          await item.fsEntity!.delete();
        }
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting ${item.name}: $e')),
          );
        }
      }
    }
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
                    itemCount: widget.imageItems.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      _precacheImages(index);
                    },
                    itemBuilder: (context, index) {
                      final item = widget.imageItems[index];
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
                          widget.imageItems[_currentIndex].name,
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
                        onPressed: () {},
                      ),
                      _ActionButton(
                        icon: Icons.delete,
                        label: 'Delete',
                        onPressed: _deleteCurrentFile,
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

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
