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
