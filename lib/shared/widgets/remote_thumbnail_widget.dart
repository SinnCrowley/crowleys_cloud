import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Reusable state-memoized thumbnail widget for remote file thumbnails.
class RemoteThumbnailWidget extends StatefulWidget {
  const RemoteThumbnailWidget({
    super.key,
    required this.thumbnailLoader,
    required this.fallbackBuilder,
    required this.isList,
    this.cacheKey,
  });

  final Future<Uint8List?> Function() thumbnailLoader;
  final Widget Function(BuildContext context, double size) fallbackBuilder;
  final bool isList;
  final Object? cacheKey;

  @override
  State<RemoteThumbnailWidget> createState() => _RemoteThumbnailWidgetState();
}

class _RemoteThumbnailWidgetState extends State<RemoteThumbnailWidget> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.thumbnailLoader();
  }

  @override
  void didUpdateWidget(RemoteThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey ||
        oldWidget.isList != widget.isList) {
      _future = widget.thumbnailLoader();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isList ? 48.0 : 120.0;
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
              errorBuilder: (ctx, err, stack) =>
                  widget.fallbackBuilder(ctx, size),
            ),
          );
        }
        return widget.fallbackBuilder(context, size);
      },
    );
  }
}
