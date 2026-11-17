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
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Provides ambient scroll velocity and fling state monitoring to descendant widgets.
///
/// When the user scrolls rapidly (velocity >= [velocityThreshold], default 400 px/s),
/// descendant thumbnail widgets can defer network requests to prevent request storms
/// during fast fling scrolling.
class ScrollThrottler extends StatefulWidget {
  const ScrollThrottler({
    super.key,
    required this.child,
    this.velocityThreshold = 400.0,
    this.idleTimeout = const Duration(milliseconds: 80),
  });

  final Widget child;
  final double velocityThreshold;
  final Duration idleTimeout;

  /// Returns true if the nearest ancestor [ScrollThrottler] is currently fast-scrolling/flinging.
  static bool isFastScrolling(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ScrollThrottlerScope>();
    return scope?.notifier?.value ?? false;
  }

  /// Returns the [ValueNotifier<bool>] for fast scrolling from the nearest ancestor [ScrollThrottler].
  static ValueNotifier<bool>? notifierOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ScrollThrottlerScope>();
    return scope?.notifier;
  }

  @override
  State<ScrollThrottler> createState() => _ScrollThrottlerState();
}

class _ScrollThrottlerState extends State<ScrollThrottler> {
  final ValueNotifier<bool> _isFastScrolling = ValueNotifier<bool>(false);
  Timer? _idleTimer;
  int _lastTimestampUs = 0;
  double _lastPixels = 0.0;

  @override
  void dispose() {
    _idleTimer?.cancel();
    _isFastScrolling.dispose();
    super.dispose();
  }

  double? _extractPrimaryVelocity(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final drag = notification.dragDetails;
      if (drag != null) {
        return drag.primaryVelocity ?? drag.velocity.pixelsPerSecond.distance;
      }
    } else if (notification is ScrollUpdateNotification) {
      final dynamic drag = notification.dragDetails;
      if (drag != null) {
        try {
          final dynamic vel = drag.primaryVelocity;
          if (vel is num) return vel.toDouble();
        } catch (_) {}
      }
    } else if (notification is ScrollStartNotification) {
      final dynamic drag = notification.dragDetails;
      if (drag != null) {
        try {
          final dynamic vel = drag.primaryVelocity;
          if (vel is num) return vel.toDouble();
        } catch (_) {}
      }
    }
    return null;
  }

  void _onScrollNotification(ScrollNotification notification) {
    final primaryVelocity = _extractPrimaryVelocity(notification)?.abs();
    if (primaryVelocity != null &&
        primaryVelocity >= widget.velocityThreshold) {
      if (!_isFastScrolling.value) {
        _isFastScrolling.value = true;
      }
      _scheduleIdleReset();
    }

    if (notification is ScrollStartNotification) {
      _lastTimestampUs = DateTime.now().microsecondsSinceEpoch;
      _lastPixels = notification.metrics.pixels;
      return;
    }

    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        final nowUs = DateTime.now().microsecondsSinceEpoch;
        final dtUs = _lastTimestampUs > 0 ? (nowUs - _lastTimestampUs) : 0;
        final currentPixels = notification.metrics.pixels;
        final scrollDelta = notification.scrollDelta?.abs();

        bool isHighVelocity = false;

        if (scrollDelta != null &&
            (scrollDelta >= 15.0 ||
                scrollDelta >= widget.velocityThreshold * 0.02)) {
          isHighVelocity = true;
        }

        if (dtUs >= 8000) {
          final dt = dtUs / 1000000.0;
          final dp = scrollDelta ?? (currentPixels - _lastPixels).abs();
          final velocity = dp / dt;

          _lastTimestampUs = nowUs;
          _lastPixels = currentPixels;

          if (velocity >= widget.velocityThreshold) {
            isHighVelocity = true;
          }
        } else if (_lastTimestampUs == 0) {
          _lastTimestampUs = nowUs;
          _lastPixels = currentPixels;
        }

        if (isHighVelocity) {
          if (!_isFastScrolling.value) {
            _isFastScrolling.value = true;
          }
          _scheduleIdleReset();
        }
      }
      return;
    }

    if (notification is ScrollEndNotification) {
      if (_idleTimer == null || !_idleTimer!.isActive) {
        if (_isFastScrolling.value) {
          _isFastScrolling.value = false;
        }
      }
      return;
    }

    if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      if (_idleTimer == null || !_idleTimer!.isActive) {
        if (_isFastScrolling.value) {
          _isFastScrolling.value = false;
        }
      }
    }
  }

  void _scheduleIdleReset() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.idleTimeout, () {
      if (mounted && _isFastScrolling.value) {
        _isFastScrolling.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _onScrollNotification(notification);
        return false; // Allow notifications to bubble up to Scrollbars and RefreshIndicators
      },
      child: ScrollThrottlerScope(
        notifier: _isFastScrolling,
        child: widget.child,
      ),
    );
  }
}

/// Inherited notifier providing scroll fling state to descendant listeners.
class ScrollThrottlerScope extends InheritedNotifier<ValueNotifier<bool>> {
  const ScrollThrottlerScope({
    super.key,
    required super.notifier,
    required super.child,
  });
}
