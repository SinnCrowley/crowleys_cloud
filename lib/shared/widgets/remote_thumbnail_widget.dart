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
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/shared/utils/blurhash_decoder.dart';
import 'package:crowleys_cloud/shared/utils/scroll_throttler.dart';

/// Reusable state-memoized thumbnail widget for remote file thumbnails.
///
/// Features:
/// 1. Instant BlurHash placeholder preview (zero network latency).
/// 2. Scroll fling throttling: suppresses network requests during high-velocity scrolling.
/// 3. RAM LRU cache instant hit: renders cached thumbnails immediately without delay.
/// 4. Smooth cross-fade transition from BlurHash placeholder to full WebP thumbnail.
class RemoteThumbnailWidget extends StatefulWidget {
  const RemoteThumbnailWidget({
    super.key,
    required this.thumbnailLoader,
    required this.fallbackBuilder,
    required this.isList,
    this.cacheKey,
    this.blurhash,
    this.crossFadeDuration = const Duration(milliseconds: 250),
    this.debounceDuration = const Duration(milliseconds: 60),
  });

  final Future<Uint8List?> Function() thumbnailLoader;
  final Widget Function(BuildContext context, double size) fallbackBuilder;
  final bool isList;
  final Object? cacheKey;
  final String? blurhash;
  final Duration crossFadeDuration;
  final Duration debounceDuration;

  @override
  State<RemoteThumbnailWidget> createState() => _RemoteThumbnailWidgetState();
}

class _RemoteThumbnailWidgetState extends State<RemoteThumbnailWidget> {
  Uint8List? _loadedBytes;
  bool _isLoading = false;
  bool _hasError = false;
  Timer? _debounceTimer;
  ValueNotifier<bool>? _scrollNotifier;
  int _transitionId = 0;

  @override
  void initState() {
    super.initState();
    _checkCacheAndSchedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToScrollThrottler();
  }

  void _subscribeToScrollThrottler() {
    final newNotifier = ScrollThrottler.notifierOf(context);
    if (_scrollNotifier != newNotifier) {
      _scrollNotifier?.removeListener(_onScrollStateChanged);
      _scrollNotifier = newNotifier;
      _scrollNotifier?.addListener(_onScrollStateChanged);
    }
  }

  void _onScrollStateChanged() {
    if (_scrollNotifier == null) return;
    final isFast = _scrollNotifier!.value;
    if (!isFast && !_isLoading && _loadedBytes == null && !_hasError) {
      _startLoading();
    }
  }

  void _checkCacheAndSchedule() {
    _debounceTimer?.cancel();

    // 1. Instant check in RAM LRU Cache
    if (widget.cacheKey != null) {
      final key = widget.cacheKey.toString();
      final mem = CacheService.instance.getMemoryThumbnail(key);
      if (mem != null) {
        if (_loadedBytes != mem) {
          _transitionId++;
        }
        _loadedBytes = mem;
        _isLoading = false;
        _hasError = false;
        return;
      }
    }

    if (_loadedBytes != null) {
      _transitionId++;
    }
    _loadedBytes = null;
    _hasError = false;

    // 2. Check if currently flinging
    final isFastScrolling = _scrollNotifier?.value ?? false;
    if (isFastScrolling) {
      _isLoading = false;
      return;
    }

    // 3. Debounce network fetch if BlurHash placeholder is available
    if (widget.blurhash != null && BlurHashDecoder.isValid(widget.blurhash)) {
      _debounceTimer = Timer(widget.debounceDuration, () {
        if (mounted && (_scrollNotifier?.value ?? false) == false) {
          _startLoading();
        }
      });
    } else {
      _startLoading();
    }
  }

  Future<void> _startLoading() async {
    _debounceTimer?.cancel();
    if (_isLoading || _loadedBytes != null || !mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final bytes = await widget.thumbnailLoader();
      if (!mounted) return;
      setState(() {
        if (_loadedBytes != bytes) {
          _transitionId++;
        }
        _loadedBytes = bytes;
        _isLoading = false;
        _hasError = bytes == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void didUpdateWidget(RemoteThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey ||
        oldWidget.isList != widget.isList ||
        oldWidget.blurhash != widget.blurhash) {
      _checkCacheAndSchedule();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollNotifier?.removeListener(_onScrollStateChanged);
    super.dispose();
  }

  Widget _buildPlaceholder(BuildContext context, double size) {
    if (widget.blurhash != null && BlurHashDecoder.isValid(widget.blurhash)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BlurHashWidget(
          blurhash: widget.blurhash!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: widget.fallbackBuilder(context, size),
      ),
    );
  }

  Widget _buildLoadedImage(BuildContext context, double size, Uint8List bytes) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (ctx, err, stack) => SizedBox(
          width: size,
          height: size,
          child: Center(
            child: widget.fallbackBuilder(ctx, size),
          ),
        ),
      ),
    );
  }

  Key _unwrapKey(Key key) {
    var k = key;
    while (k is ValueKey && k.value is Key) {
      k = k.value as Key;
    }
    return k;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isList ? 48.0 : 120.0;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: widget.crossFadeDuration,
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          final seenKeys = <Key>{};
          final uniquePrevious = <Widget>[];
          if (currentChild?.key != null) {
            seenKeys.add(_unwrapKey(currentChild!.key!));
          }
          for (final child in previousChildren.reversed) {
            final key = child.key != null ? _unwrapKey(child.key!) : null;
            if (key == null || seenKeys.add(key)) {
              uniquePrevious.add(child);
            }
          }
          return Stack(
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.center,
            children: <Widget>[
              ...uniquePrevious.reversed,
              ?currentChild,
            ],
          );
        },
        child: _loadedBytes != null
            ? KeyedSubtree(
                key: const ValueKey('loaded_thumb'),
                child: _buildLoadedImage(context, size, _loadedBytes!),
              )
            : KeyedSubtree(
                key: ValueKey('placeholder_thumb_$_transitionId'),
                child: _buildPlaceholder(context, size),
              ),
      ),
    );
  }
}
