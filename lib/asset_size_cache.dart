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
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AssetCacheEntry {
  final int size;
  final int modifiedTimestamp;

  AssetCacheEntry({required this.size, required this.modifiedTimestamp});

  Map<String, dynamic> toJson() => {'s': size, 'm': modifiedTimestamp};

  factory AssetCacheEntry.fromJson(Map<String, dynamic> json) {
    return AssetCacheEntry(
      size: json['s'] as int,
      modifiedTimestamp: json['m'] as int,
    );
  }
}

class AssetSizeCache {
  AssetSizeCache._();

  static final Map<String, AssetCacheEntry> _cache = {};
  static File? _cacheFile;
  static bool _loaded = false;
  static Timer? _saveTimer;

  /// Loads cached sizes from the application support directory into memory.
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final supportDir = await getApplicationSupportDirectory();
      _cacheFile = File(p.join(supportDir.path, 'asset_sizes_cache.json'));
      if (await _cacheFile!.exists()) {
        final content = await _cacheFile!.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        map.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _cache[key] = AssetCacheEntry.fromJson(value);
          }
        });
      }
    } catch (_) {
      // Quietly handle errors to avoid breaking the app if IO fails
    }
    _loaded = true;
  }

  /// Retrieves the size in bytes if cached and matching the current modification date.
  static int? getSize(String assetId, DateTime modifiedDate) {
    final entry = _cache[assetId];
    if (entry == null) return null;

    // Invalidation check: if modified time differs, the file was modified
    if (entry.modifiedTimestamp == modifiedDate.millisecondsSinceEpoch) {
      return entry.size;
    }
    return null;
  }

  /// Caches a size with a modification date and schedules a debounced save.
  static void setSize(String assetId, int size, DateTime modifiedDate) {
    final newTimestamp = modifiedDate.millisecondsSinceEpoch;
    final entry = _cache[assetId];
    if (entry != null &&
        entry.size == size &&
        entry.modifiedTimestamp == newTimestamp) {
      return;
    }
    _cache[assetId] = AssetCacheEntry(
      size: size,
      modifiedTimestamp: newTimestamp,
    );
    _saveDebounced();
  }

  /// Removes cached sizes for asset IDs that are no longer valid.
  static void remove(String assetId) {
    if (_cache.containsKey(assetId)) {
      _cache.remove(assetId);
      _saveDebounced();
    }
  }

  /// Keeps the cache size in check by removing oldest entries if it exceeds [maxEntries].
  /// This is a passive GC routine.
  static void pruneOldEntries({required List<String> activeIds}) {
    // If the cache is getting large, we can perform active pruning of items
    // not present in the current viewing lists to keep size bounded.
    if (_cache.length > 10000) {
      final activeSet = activeIds.toSet();
      _cache.removeWhere((key, _) => !activeSet.contains(key));
      _saveDebounced();
    }
  }

  static void _saveDebounced() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      if (_cacheFile == null) return;
      try {
        final mapToSave = _cache.map(
          (key, value) => MapEntry(key, value.toJson()),
        );
        await _cacheFile!.writeAsString(jsonEncode(mapToSave));
      } catch (_) {}
    });
  }

  /// Clear cache contents (e.g., when clearing application cache).
  static Future<void> clear() async {
    _cache.clear();
    _saveTimer?.cancel();
    if (_cacheFile != null && await _cacheFile!.exists()) {
      try {
        await _cacheFile!.delete();
      } catch (_) {}
    }
  }
}
