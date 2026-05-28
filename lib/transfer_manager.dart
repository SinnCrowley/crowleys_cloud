import 'dart:async';

import 'package:flutter/foundation.dart';

enum TransferDirection { upload, download }

enum TransferStatus { queued, running, paused, completed, failed, canceled }

class TransferItem {
  TransferItem({
    required this.id,
    required this.name,
    required this.direction,
    required this.totalBytes,
  });

  final String id;
  final String name;
  final TransferDirection direction;
  final int totalBytes;
  int transferredBytes = 0;
  TransferStatus status = TransferStatus.queued;
  String? error;

  double get progress {
    if (totalBytes <= 0) return status == TransferStatus.completed ? 1 : 0;
    return (transferredBytes / totalBytes).clamp(0, 1);
  }

  bool get isActive =>
      status == TransferStatus.queued ||
      status == TransferStatus.running ||
      status == TransferStatus.paused;
}

class TransferItemDraft {
  const TransferItemDraft({
    required this.name,
    required this.direction,
    required this.totalBytes,
  });

  final String name;
  final TransferDirection direction;
  final int totalBytes;
}

class TransferCanceledException implements Exception {}

class TransferItemCanceledException implements Exception {
  TransferItemCanceledException(this.item);

  final TransferItem item;
}

class TransferManager extends ChangeNotifier {
  static const _progressNotifyDelay = Duration(milliseconds: 500);

  final List<TransferItem> items = [];
  bool _paused = false;
  bool _canceled = false;
  Completer<void>? _resumeCompleter;
  Timer? _progressNotifyTimer;
  final Map<TransferItem, int> _pendingProgressBytes = {};
  int _nextId = 0;

  bool get hasItems => items.isNotEmpty;
  bool get hasActiveTransfers => items.any((item) => item.isActive);
  bool get isPaused => _paused;
  bool get isCanceled => _canceled;
  int get activeCount => items.where((item) => item.isActive).length;
  int get completedCount =>
      items.where((item) => item.status == TransferStatus.completed).length;
  int get totalCount => items.length;

  int get totalBytes => items.fold(0, (sum, item) => sum + item.totalBytes);
  int get transferredBytes =>
      items.fold(0, (sum, item) => sum + item.transferredBytes);

  double get progress {
    final total = totalBytes;
    if (total <= 0) return totalCount == 0 ? 0 : completedCount / totalCount;
    return (transferredBytes / total).clamp(0, 1);
  }

  String get summaryLabel {
    final percent = (progress * 100).round();
    return '$percent%  $completedCount/$totalCount files';
  }

  TransferItem addItem({
    required String name,
    required TransferDirection direction,
    required int totalBytes,
  }) {
    final item = _createItem(
      name: name,
      direction: direction,
      totalBytes: totalBytes,
    );
    items.add(item);
    _canceled = false;
    _notifyNow();
    return item;
  }

  List<TransferItem> addItems(List<TransferItemDraft> drafts) {
    final added = drafts
        .map(
          (draft) => _createItem(
            name: draft.name,
            direction: draft.direction,
            totalBytes: draft.totalBytes,
          ),
        )
        .toList(growable: false);
    items.addAll(added);
    if (added.isNotEmpty) {
      _canceled = false;
      _notifyNow();
    }
    return added;
  }

  void startItem(TransferItem item) {
    if (item.status == TransferStatus.canceled) return;
    item.status = TransferStatus.running;
    item.error = null;
    _notifyNow();
  }

  void updateItem(TransferItem item, int transferredBytes) {
    if (item.status == TransferStatus.canceled) return;
    if (item.status == TransferStatus.paused) {
      item.status = TransferStatus.running;
    }
    _pendingProgressBytes[item] = transferredBytes.clamp(0, item.totalBytes);
    _scheduleProgressNotify();
  }

  void completeItem(TransferItem item) {
    if (item.status == TransferStatus.canceled) return;
    _pendingProgressBytes.remove(item);
    item.transferredBytes = item.totalBytes;
    item.status = TransferStatus.completed;
    _notifyNow();
  }

  void failItem(TransferItem item, String error) {
    if (item.status == TransferStatus.canceled) return;
    _pendingProgressBytes.remove(item);
    item.status = TransferStatus.failed;
    item.error = error;
    _notifyNow();
  }

  void cancelItem(TransferItem item) {
    if (item.status == TransferStatus.completed ||
        item.status == TransferStatus.failed ||
        item.status == TransferStatus.canceled) {
      return;
    }
    _pendingProgressBytes.remove(item);
    item.status = TransferStatus.canceled;
    item.error = null;
    _notifyNow();
  }

  void cancelAll() {
    _canceled = true;
    _progressNotifyTimer?.cancel();
    _progressNotifyTimer = null;
    _pendingProgressBytes.clear();
    _resumeCompleter?.complete();
    _resumeCompleter = null;
    _paused = false;
    for (final item in items.where((item) => item.isActive)) {
      item.status = TransferStatus.canceled;
    }
    items.clear();
    _notifyNow();
  }

  void togglePause() {
    if (_paused) {
      _paused = false;
      _resumeCompleter?.complete();
      _resumeCompleter = null;
    } else {
      _paused = true;
      for (final item in items.where(
        (item) => item.status == TransferStatus.running,
      )) {
        item.status = TransferStatus.paused;
      }
      _resumeCompleter = Completer<void>();
    }
    _notifyNow();
  }

  Future<void> waitIfPaused() async {
    if (_canceled) throw TransferCanceledException();
    while (_paused) {
      await (_resumeCompleter ??= Completer<void>()).future;
      if (_canceled) throw TransferCanceledException();
    }
  }

  void throwIfCanceled() {
    if (_canceled) throw TransferCanceledException();
  }

  void throwIfItemCanceled(TransferItem item) {
    if (item.status == TransferStatus.canceled) {
      throw TransferItemCanceledException(item);
    }
  }

  void clearFinished() {
    items.removeWhere((item) => !item.isActive);
    _notifyNow();
  }

  TransferItem _createItem({
    required String name,
    required TransferDirection direction,
    required int totalBytes,
  }) {
    return TransferItem(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_nextId++}',
      name: name,
      direction: direction,
      totalBytes: totalBytes,
    );
  }

  void _scheduleProgressNotify() {
    if (_progressNotifyTimer?.isActive ?? false) return;
    _progressNotifyTimer = Timer(_progressNotifyDelay, _notifyNow);
  }

  void _notifyNow() {
    _progressNotifyTimer?.cancel();
    _progressNotifyTimer = null;
    if (_pendingProgressBytes.isNotEmpty) {
      for (final entry in _pendingProgressBytes.entries) {
        entry.key.transferredBytes = entry.value;
      }
      _pendingProgressBytes.clear();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _progressNotifyTimer?.cancel();
    super.dispose();
  }
}
