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
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crowleys_cloud/sync_service.dart';
import 'package:crowleys_cloud/transfer_manager.dart';
import 'package:http/http.dart' as http;

/// Options configuring a chunked upload operation.
class ChunkedUploadOptions {
  const ChunkedUploadOptions({
    this.chunkSize = 2 * 1024 * 1024, // 2 MB
    this.maxRetriesPerChunk = 3,
    this.initialBackoff = const Duration(milliseconds: 20),
    this.scope = 'private',
    this.resume = true,
  });

  final int chunkSize;
  final int maxRetriesPerChunk;
  final Duration initialBackoff;
  final String scope;
  final bool resume;
}

/// Recorded chunk upload request received by MockChunkedServer.
class ReceivedChunk {
  ReceivedChunk({
    required this.path,
    required this.offset,
    required this.total,
    required this.isLast,
    required this.bytes,
    required this.token,
  });

  final String path;
  final int offset;
  final int total;
  final bool isLast;
  final List<int> bytes;
  final String token;
}

/// In-memory mock Drogon server implementing chunked resumable upload endpoints:
/// - GET  /api/files/upload-status?path=...&scope=...
/// - POST /api/files?path=...&scope=...&offset=...&total=...&is_last=...
class MockChunkedServer {
  final Map<String, List<int>> _serverFiles = {};
  final List<ReceivedChunk> receivedChunks = [];
  int? failOnChunkIndex;
  Exception? failWithException;
  int? expireTokenOnChunkIndex;
  int getStatusCallCount = 0;
  String currentValidToken = 'valid_token_v1';
  final String renewedToken = 'valid_token_v2';

  void reset() {
    _serverFiles.clear();
    receivedChunks.clear();
    failOnChunkIndex = null;
    failWithException = null;
    expireTokenOnChunkIndex = null;
    getStatusCallCount = 0;
    currentValidToken = 'valid_token_v1';
  }

  Future<http.Response> handleGetStatus(Uri uri) async {
    getStatusCallCount++;
    final path = uri.queryParameters['path'] ?? '';
    final existingBytes = _serverFiles[path]?.length ?? 0;
    return http.Response(
      jsonEncode({'ok': true, 'bytes_received': existingBytes}),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  Future<http.Response> handlePostChunk(
    Uri uri,
    List<int> bodyBytes,
    Map<String, String> headers,
  ) async {
    final authHeader = headers['authorization'] ?? '';
    final token = authHeader.replaceFirst('Bearer ', '').trim();
    final path = uri.queryParameters['path'] ?? '';
    final offset = int.tryParse(uri.queryParameters['offset'] ?? '0') ?? 0;
    final total = int.tryParse(uri.queryParameters['total'] ?? '0') ?? 0;
    final isLast = uri.queryParameters['is_last'] == 'true';

    final chunkIdx = receivedChunks.length;

    // Simulate token expiration (401)
    if (expireTokenOnChunkIndex != null &&
        chunkIdx == expireTokenOnChunkIndex) {
      if (token != renewedToken) {
        return http.Response(
          jsonEncode({'ok': false, 'error': 'token_expired'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }
    }

    // Simulate transient network drop
    if (failOnChunkIndex != null && chunkIdx == failOnChunkIndex) {
      failOnChunkIndex = null; // Clear so retry succeeds
      throw failWithException ??
          const SocketException('Connection reset by peer');
    }

    receivedChunks.add(
      ReceivedChunk(
        path: path,
        offset: offset,
        total: total,
        isLast: isLast,
        bytes: bodyBytes,
        token: token,
      ),
    );

    final fileBuffer = _serverFiles.putIfAbsent(path, () => <int>[]);
    if (offset == 0) {
      fileBuffer.clear();
    }
    fileBuffer.addAll(bodyBytes);

    final completed = (total > 0 && fileBuffer.length >= total) || isLast;
    return http.Response(
      jsonEncode({
        'ok': true,
        'completed': completed,
        'bytes_received': fileBuffer.length,
      }),
      completed ? 201 : 200,
      headers: {'content-type': 'application/json'},
    );
  }
}

/// Reference implementation of ResumableUploadTransport matching PROJECT.md §4 contract.
class ResumableUploadTransport {
  ResumableUploadTransport({
    required this.server,
    required this.baseUrl,
    required this.tokenProvider,
    required this.onRefreshToken,
  });

  final MockChunkedServer server;
  final String baseUrl;
  final Future<String> Function() tokenProvider;
  final Future<void> Function() onRefreshToken;

  Future<int> getUploadStatus({
    required String remotePath,
    String scope = 'private',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/files/upload-status',
    ).replace(queryParameters: {'scope': scope, 'path': remotePath});
    final response = await server.handleGetStatus(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['bytes_received'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<void> upload({
    required File file,
    required String remotePath,
    ChunkedUploadOptions options = const ChunkedUploadOptions(),
    TransferItem? transferItem,
    TransferManager? transferManager,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final totalBytes = await file.length();

    // 0-byte file edge case:
    if (totalBytes == 0) {
      final token = await tokenProvider();
      final uri = Uri.parse('$baseUrl/api/files').replace(
        queryParameters: {
          'scope': options.scope,
          'path': remotePath,
          'offset': '0',
          'total': '0',
          'is_last': 'true',
        },
      );
      await server.handlePostChunk(uri, const [], {
        'authorization': 'Bearer $token',
      });
      onProgress?.call(0, 0);
      return;
    }

    int offset = 0;
    if (options.resume) {
      final serverBytes = await getUploadStatus(
        remotePath: remotePath,
        scope: options.scope,
      );
      if (serverBytes > 0 && serverBytes < totalBytes) {
        offset = serverBytes;
      }
    }

    final raf = await file.open(mode: FileMode.read);
    try {
      while (offset < totalBytes) {
        transferManager?.throwIfCanceled();
        if (transferItem != null) {
          transferManager?.throwIfItemCanceled(transferItem);
        }
        await transferManager?.waitIfPaused();
        if (transferItem != null) {
          transferManager?.throwIfItemCanceled(transferItem);
        }

        final currentChunkSize = math.min(
          options.chunkSize,
          totalBytes - offset,
        );
        final isLast = (offset + currentChunkSize) >= totalBytes;

        await raf.setPosition(offset);
        final bytes = await raf.read(currentChunkSize);

        // Upload chunk with retry & 401 refresh handling
        await _sendChunkWithRetry(
          remotePath: remotePath,
          scope: options.scope,
          offset: offset,
          totalBytes: totalBytes,
          isLast: isLast,
          bytes: bytes,
          options: options,
        );

        offset += bytes.length;
        onProgress?.call(offset, totalBytes);
        if (transferItem != null && transferManager != null) {
          transferManager.updateItem(transferItem, offset);
        }
      }
      if (transferItem != null &&
          transferManager != null &&
          offset >= totalBytes) {
        transferManager.completeItem(transferItem);
      }
    } finally {
      await raf.close();
    }
  }

  Future<void> _sendChunkWithRetry({
    required String remotePath,
    required String scope,
    required int offset,
    required int totalBytes,
    required bool isLast,
    required List<int> bytes,
    required ChunkedUploadOptions options,
  }) async {
    var attempts = 0;
    var backoff = options.initialBackoff;

    while (attempts < options.maxRetriesPerChunk) {
      attempts++;
      final token = await tokenProvider();
      final uri = Uri.parse('$baseUrl/api/files').replace(
        queryParameters: {
          'scope': scope,
          'path': remotePath,
          'offset': offset.toString(),
          'total': totalBytes.toString(),
          'is_last': isLast.toString(),
        },
      );

      try {
        final response = await server.handlePostChunk(uri, bytes, {
          'authorization': 'Bearer $token',
        });

        if (response.statusCode == 401) {
          // Token expired mid-transfer: refresh and retry current chunk
          await onRefreshToken();
          continue;
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }

        throw HttpException('HTTP ${response.statusCode}: ${response.body}');
      } on SocketException catch (_) {
        if (attempts >= options.maxRetriesPerChunk) rethrow;
        await Future<void>.delayed(backoff);
        backoff *= 2;
      }
    }
  }
}

/// Pure Dart atomic in-memory implementation of SyncStateStore verifying WAL/atomic semantics.
class AtomicInMemorySyncStateStore implements SyncStateStore {
  final Map<String, SyncFileRecord> _records = {};
  final Map<String, SyncRunResult> _results = {};
  int writeCount = 0;
  int readCount = 0;

  String _key(String serverId, String localPath, String remotePath) =>
      '$serverId|$localPath|$remotePath';

  @override
  Future<SyncFileRecord?> readRecord(
    String serverId,
    String localPath,
    String remotePath,
  ) async {
    readCount++;
    return _records[_key(serverId, localPath, remotePath)];
  }

  @override
  Future<void> saveRecord(String serverId, SyncFileRecord record) async {
    writeCount++;
    // Atomic single-row upsert: modifies only 1 entry in O(1)
    _records[_key(serverId, record.localPath, record.remotePath)] = record;
  }

  @override
  Future<SyncRunResult?> readLastResult(String serverId) async {
    readCount++;
    return _results[serverId];
  }

  @override
  Future<void> saveLastResult(String serverId, SyncRunResult result) async {
    writeCount++;
    _results[serverId] = result;
  }

  int get totalRecordCount => _records.length;
}

/// Custom TrackingFile for R1 statSync detection.
class StatTrackingFile implements File {
  StatTrackingFile(this._realFile);

  final File _realFile;
  int statSyncCalls = 0;
  int statCalls = 0;

  @override
  String get path => _realFile.path;

  @override
  FileStat statSync() {
    statSyncCalls++;
    return _realFile.statSync();
  }

  @override
  Future<FileStat> stat() async {
    statCalls++;
    return _realFile.stat();
  }

  // Delegate essential methods to underlying real file
  @override
  bool existsSync() => _realFile.existsSync();

  @override
  Future<bool> exists() => _realFile.exists();

  @override
  int lengthSync() => _realFile.lengthSync();

  @override
  Future<int> length() => _realFile.length();

  @override
  Uri get uri => _realFile.uri;

  @override
  File get absolute => _realFile.absolute;

  @override
  bool get isAbsolute => _realFile.isAbsolute;

  @override
  Directory get parent => _realFile.parent;

  @override
  Future<File> copy(String newPath) => _realFile.copy(newPath);

  @override
  File copySync(String newPath) => _realFile.copySync(newPath);

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) =>
      _realFile.create(recursive: recursive, exclusive: exclusive);

  @override
  void createSync({bool recursive = false, bool exclusive = false}) =>
      _realFile.createSync(recursive: recursive, exclusive: exclusive);

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      _realFile.delete(recursive: recursive);

  @override
  void deleteSync({bool recursive = false}) =>
      _realFile.deleteSync(recursive: recursive);

  @override
  Future<DateTime> lastAccessed() => _realFile.lastAccessed();

  @override
  DateTime lastAccessedSync() => _realFile.lastAccessedSync();

  @override
  Future<DateTime> lastModified() => _realFile.lastModified();

  @override
  DateTime lastModifiedSync() => _realFile.lastModifiedSync();

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      _realFile.open(mode: mode);

  @override
  Stream<List<int>> openRead([int? start, int? end]) =>
      _realFile.openRead(start, end);

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) =>
      _realFile.openSync(mode: mode);

  @override
  IOSink openWrite({
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) => _realFile.openWrite(mode: mode, encoding: encoding);

  @override
  Future<Uint8List> readAsBytes() => _realFile.readAsBytes();

  @override
  Uint8List readAsBytesSync() => _realFile.readAsBytesSync();

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) =>
      _realFile.readAsLines(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) =>
      _realFile.readAsLinesSync(encoding: encoding);

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      _realFile.readAsString(encoding: encoding);

  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      _realFile.readAsStringSync(encoding: encoding);

  @override
  Future<File> rename(String newPath) => _realFile.rename(newPath);

  @override
  File renameSync(String newPath) => _realFile.renameSync(newPath);

  @override
  Future<String> resolveSymbolicLinks() => _realFile.resolveSymbolicLinks();

  @override
  String resolveSymbolicLinksSync() => _realFile.resolveSymbolicLinksSync();

  @override
  Future<void> setLastAccessed(DateTime time) =>
      _realFile.setLastAccessed(time);

  @override
  void setLastAccessedSync(DateTime time) =>
      _realFile.setLastAccessedSync(time);

  @override
  Future<void> setLastModified(DateTime time) =>
      _realFile.setLastModified(time);

  @override
  void setLastModifiedSync(DateTime time) =>
      _realFile.setLastModifiedSync(time);

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) => _realFile.writeAsBytes(bytes, mode: mode, flush: flush);

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) => _realFile.writeAsBytesSync(bytes, mode: mode, flush: flush);

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => _realFile.writeAsString(
    contents,
    mode: mode,
    encoding: encoding,
    flush: flush,
  );

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => _realFile.writeAsStringSync(
    contents,
    mode: mode,
    encoding: encoding,
    flush: flush,
  );

  @override
  Stream<FileSystemEvent> watch({
    int events = FileSystemEvent.all,
    bool recursive = false,
  }) => _realFile.watch(events: events, recursive: recursive);
}
