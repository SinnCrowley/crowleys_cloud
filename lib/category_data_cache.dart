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
import 'package:crowleys_cloud/file_browser_controller.dart' show SortBy;
import 'package:crowleys_cloud/file_item.dart';
import 'package:flutter/foundation.dart';

/// Single cached category record with expiration metadata.
class CategoryCacheEntry {
  CategoryCacheEntry({
    required this.categoryName,
    required List<FileItem> files,
    this.sortBy,
    this.sortAscending,
    DateTime? timestamp,
    DateTime? lastAccessed,
  }) : files = List.unmodifiable(files),
       timestamp = timestamp ?? DateTime.now(),
       lastAccessed = lastAccessed ?? timestamp ?? DateTime.now();

  final String categoryName;
  final List<FileItem> files;
  final SortBy? sortBy;
  final bool? sortAscending;
  final DateTime timestamp;
  DateTime lastAccessed;

  bool isExpired([Duration ttl = CategoryDataCache.defaultTtl]) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

/// Short-lived Stale-While-Revalidate cache for category file listings.
///
/// Ensures 0ms instant display on re-entry within [defaultTtl] (~45 seconds)
/// while automatically releasing memory on TTL expiry or eviction.
class CategoryDataCache {
  static const Duration defaultTtl = Duration(seconds: 45);
  static const int maxEntries = 10;
  static const int maxTotalCachedFiles = 5000;

  static final CategoryDataCache _instance = CategoryDataCache._internal();
  static CategoryDataCache get instance => _instance;

  CategoryDataCache._internal();

  factory CategoryDataCache() => _instance;

  final Map<String, CategoryCacheEntry> _cache = {};
  Timer? _evictionTimer;

  /// Retrieves cached entry metadata for [categoryName] if present and not expired.
  CategoryCacheEntry? getEntry(
    String categoryName, {
    Duration ttl = defaultTtl,
  }) {
    final entry = _cache[categoryName];
    if (entry == null) return null;
    if (entry.isExpired(ttl)) {
      _cache.remove(categoryName);
      if (_cache.isEmpty) {
        _evictionTimer?.cancel();
        _evictionTimer = null;
      }
      return null;
    }
    entry.lastAccessed = DateTime.now();
    return entry;
  }

  /// Retrieves cached file items for [categoryName] if present and not expired.
  List<FileItem>? get(String categoryName, {Duration ttl = defaultTtl}) {
    return getEntry(categoryName, ttl: ttl)?.files;
  }

  /// Puts category file items into the cache, evicting expired entries.
  void put(
    String categoryName,
    List<FileItem> files, {
    SortBy? sortBy,
    bool? sortAscending,
  }) {
    _evictExpired();
    if (!_cache.containsKey(categoryName) && _cache.length >= maxEntries) {
      final oldestKey = _cache.entries
          .reduce(
            (a, b) =>
                a.value.lastAccessed.isBefore(b.value.lastAccessed) ? a : b,
          )
          .key;
      _cache.remove(oldestKey);
    }
    final boundedFiles = files.length > maxTotalCachedFiles
        ? files.sublist(0, maxTotalCachedFiles)
        : files;
    _cache[categoryName] = CategoryCacheEntry(
      categoryName: categoryName,
      files: boundedFiles,
      sortBy: sortBy,
      sortAscending: sortAscending,
    );
    _evictOnMemoryPressure();
    _ensureEvictionTimer();
  }

  /// Evicts oldest entries if cumulative cached file count exceeds [maxTotalCachedFiles].
  void _evictOnMemoryPressure() {
    var totalFiles = _cache.values.fold<int>(
      0,
      (sum, e) => sum + e.files.length,
    );
    while (totalFiles > maxTotalCachedFiles && _cache.length > 1) {
      final oldestKey = _cache.entries
          .reduce(
            (a, b) =>
                a.value.lastAccessed.isBefore(b.value.lastAccessed) ? a : b,
          )
          .key;
      final removed = _cache.remove(oldestKey);
      if (removed != null) {
        totalFiles -= removed.files.length;
      }
    }
  }

  /// Invalidates cached entries for [categoryName] (e.g. after mutations).
  void invalidate(String categoryName) {
    _cache.remove(categoryName);
    if (_cache.isEmpty) {
      _evictionTimer?.cancel();
      _evictionTimer = null;
    }
  }

  /// Clears all cached categories and cancels the eviction timer.
  void clear() {
    _cache.clear();
    _evictionTimer?.cancel();
    _evictionTimer = null;
  }

  void _evictExpired() {
    final now = DateTime.now();
    _cache.removeWhere(
      (_, entry) => now.difference(entry.timestamp) > defaultTtl,
    );
    if (_cache.isEmpty) {
      _evictionTimer?.cancel();
      _evictionTimer = null;
    }
  }

  void _ensureEvictionTimer() {
    _evictionTimer?.cancel();
    _evictionTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _evictExpired();
    });
  }

  @visibleForTesting
  int get entryCount => _cache.length;

  @visibleForTesting
  bool hasEntry(String categoryName) => _cache.containsKey(categoryName);

  @visibleForTesting
  void evictExpired() => _evictExpired();

  @visibleForTesting
  void putWithTimestamp(
    String categoryName,
    List<FileItem> files,
    DateTime timestamp, {
    SortBy? sortBy,
    bool? sortAscending,
  }) {
    _cache[categoryName] = CategoryCacheEntry(
      categoryName: categoryName,
      files: files,
      sortBy: sortBy,
      sortAscending: sortAscending,
      timestamp: timestamp,
    );
  }
}
