import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum SyncRunStatus { success, partialFailure, authRequired, noFiles, failed }

class SyncRunResult {
  const SyncRunResult({
    required this.status,
    required this.scannedFiles,
    required this.uploadedFiles,
    required this.skippedFiles,
    required this.failedFiles,
    required this.startedAt,
    required this.finishedAt,
    this.message,
  });

  final SyncRunStatus status;
  final int scannedFiles;
  final int uploadedFiles;
  final int skippedFiles;
  final int failedFiles;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String? message;

  bool get isSuccess =>
      status == SyncRunStatus.success || status == SyncRunStatus.noFiles;

  Map<String, Object?> toJson() {
    return {
      'status': status.name,
      'scannedFiles': scannedFiles,
      'uploadedFiles': uploadedFiles,
      'skippedFiles': skippedFiles,
      'failedFiles': failedFiles,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'finishedAt': finishedAt.toUtc().toIso8601String(),
      'message': message,
    };
  }

  static SyncRunResult? fromJson(Map<String, Object?> json) {
    final statusName = json['status'] as String?;
    final status = SyncRunStatus.values
        .where((value) => value.name == statusName)
        .firstOrNull;
    final startedAtRaw = json['startedAt'] as String?;
    final finishedAtRaw = json['finishedAt'] as String?;
    if (status == null || startedAtRaw == null || finishedAtRaw == null) {
      return null;
    }
    return SyncRunResult(
      status: status,
      scannedFiles: (json['scannedFiles'] as num?)?.toInt() ?? 0,
      uploadedFiles: (json['uploadedFiles'] as num?)?.toInt() ?? 0,
      skippedFiles: (json['skippedFiles'] as num?)?.toInt() ?? 0,
      failedFiles: (json['failedFiles'] as num?)?.toInt() ?? 0,
      startedAt: DateTime.parse(startedAtRaw),
      finishedAt: DateTime.parse(finishedAtRaw),
      message: json['message'] as String?,
    );
  }
}

class SyncFileRecord {
  const SyncFileRecord({
    required this.localPath,
    required this.remotePath,
    required this.sizeBytes,
    required this.modifiedAtMillis,
    required this.uploadedAt,
  });

  final String localPath;
  final String remotePath;
  final int sizeBytes;
  final int modifiedAtMillis;
  final DateTime uploadedAt;

  bool matches(FileStat stat, String nextRemotePath) {
    return remotePath == nextRemotePath &&
        sizeBytes == stat.size &&
        modifiedAtMillis == stat.modified.toUtc().millisecondsSinceEpoch;
  }

  Map<String, Object?> toJson() {
    return {
      'localPath': localPath,
      'remotePath': remotePath,
      'sizeBytes': sizeBytes,
      'modifiedAtMillis': modifiedAtMillis,
      'uploadedAt': uploadedAt.toUtc().toIso8601String(),
    };
  }

  static SyncFileRecord? fromJson(Map<String, Object?> json) {
    final localPath = json['localPath'] as String?;
    final remotePath = json['remotePath'] as String?;
    final uploadedAtRaw = json['uploadedAt'] as String?;
    if (localPath == null || remotePath == null || uploadedAtRaw == null) {
      return null;
    }
    return SyncFileRecord(
      localPath: localPath,
      remotePath: remotePath,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      modifiedAtMillis: (json['modifiedAtMillis'] as num?)?.toInt() ?? 0,
      uploadedAt: DateTime.parse(uploadedAtRaw),
    );
  }
}

abstract class SyncStateStore {
  Future<SyncFileRecord?> readRecord(
    String serverId,
    String localPath,
    String remotePath,
  );

  Future<void> saveRecord(String serverId, SyncFileRecord record);

  Future<SyncRunResult?> readLastResult(String serverId);

  Future<void> saveLastResult(String serverId, SyncRunResult result);
}

class FileSyncStateStore implements SyncStateStore {
  const FileSyncStateStore({Future<File> Function()? fileProvider})
    : _fileProvider = fileProvider;

  final Future<File> Function()? _fileProvider;

  @override
  Future<SyncFileRecord?> readRecord(
    String serverId,
    String localPath,
    String remotePath,
  ) async {
    final data = await _load();
    final server = _serverData(data, serverId, create: false);
    final files = server?['files'] as Map<String, Object?>?;
    if (files == null) return null;
    final key = '$localPath:$remotePath';
    var raw = files[key] ?? files[localPath];
    if (raw is! Map) {
      final prefix = '$localPath:';
      final matchKey = files.keys.firstWhere(
        (k) => k.startsWith(prefix),
        orElse: () => '',
      );
      if (matchKey.isNotEmpty) {
        raw = files[matchKey];
      }
    }
    if (raw is! Map) return null;
    return SyncFileRecord.fromJson(Map<String, Object?>.from(raw));
  }

  @override
  Future<void> saveRecord(String serverId, SyncFileRecord record) async {
    final data = await _load();
    final server = _serverData(data, serverId, create: true)!;
    final files = Map<String, Object?>.from(
      (server['files'] as Map?) ?? const <String, Object?>{},
    );
    final key = '${record.localPath}:${record.remotePath}';
    files[key] = record.toJson();
    server['files'] = files;
    await _save(data);
  }

  @override
  Future<SyncRunResult?> readLastResult(String serverId) async {
    final data = await _load();
    final server = _serverData(data, serverId, create: false);
    final raw = server?['lastResult'];
    if (raw is! Map) return null;
    return SyncRunResult.fromJson(Map<String, Object?>.from(raw));
  }

  @override
  Future<void> saveLastResult(String serverId, SyncRunResult result) async {
    final data = await _load();
    final server = _serverData(data, serverId, create: true)!;
    server['lastResult'] = result.toJson();
    await _save(data);
  }

  Map<String, Object?>? _serverData(
    Map<String, Object?> data,
    String serverId, {
    required bool create,
  }) {
    final servers = Map<String, Object?>.from(
      (data['servers'] as Map?) ?? const <String, Object?>{},
    );
    data['servers'] = servers;
    final existing = servers[serverId];
    if (existing is Map) {
      final server = Map<String, Object?>.from(existing);
      servers[serverId] = server;
      return server;
    }
    if (!create) return null;
    final server = <String, Object?>{};
    servers[serverId] = server;
    return server;
  }

  Future<Map<String, Object?>> _load() async {
    final file = await _resolveFile();
    if (!await file.exists()) return <String, Object?>{'servers': {}};
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return <String, Object?>{'servers': {}};
    return Map<String, Object?>.from(jsonDecode(raw) as Map);
  }

  Future<void> _save(Map<String, Object?> data) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(data));
  }

  Future<File> _resolveFile() async {
    final fileProvider = _fileProvider;
    if (fileProvider != null) return fileProvider();
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'sync_state.json'));
  }
}

class SyncCandidate {
  const SyncCandidate({required this.file, required this.remotePath});

  final File file;
  final String remotePath;
}

abstract class SyncFileScanner {
  Future<List<SyncCandidate>> scan(ServerProfile server);
}

class DeviceSyncFileScanner implements SyncFileScanner {
  DeviceSyncFileScanner({
    this.externalStorageDirectoriesProvider,
    AppSettingsService? settingsService,
  }) : _settingsService = settingsService ?? AppSettingsService();

  final Future<List<Directory>?> Function()? externalStorageDirectoriesProvider;
  final AppSettingsService _settingsService;

  @override
  Future<List<SyncCandidate>> scan(ServerProfile server) async {
    final prefs = server.syncPrefs;
    final target = await _targetDirectory(prefs);
    final selectedCategories = _stringList(prefs['syncCategories']);
    final selectedFolders = _stringList(prefs['syncFolders']);
    final byLocalPath = <String, SyncCandidate>{};

    if (selectedCategories.isNotEmpty) {
      final root = await _storageRoot();
      if (root != null) {
        await _scanDirectory(
          root,
          onFile: (file) async {
            final category = _categoryForFile(file);
            if (category == null || !selectedCategories.contains(category)) {
              return;
            }
            final remotePath = p.posix.join(
              target,
              category,
              p.basename(file.path),
            );
            final absolutePath = await _identityPath(file);
            final isInSelectedFolder = selectedFolders.any((folderPath) {
              final normalizedFolder = p.normalize(p.absolute(folderPath));
              return absolutePath == normalizedFolder ||
                  absolutePath.startsWith(normalizedFolder + p.separator);
            });
            if (isInSelectedFolder) {
              return;
            }
            byLocalPath.putIfAbsent(
              absolutePath,
              () => SyncCandidate(file: file, remotePath: remotePath),
            );
          },
        );
      }
    }

    for (final folderPath in selectedFolders) {
      final folder = Directory(folderPath);
      if (!await folder.exists()) continue;
      final folderName = p.basename(folder.path);
      await _scanDirectory(
        folder,
        onFile: (file) async {
          final rel = p.relative(file.path, from: folder.path);
          final remotePath = p.posix.join(
            target,
            'folders',
            folderName,
            p.split(rel).join('/'),
          );
          byLocalPath[await _identityPath(file)] = SyncCandidate(
            file: file,
            remotePath: remotePath,
          );
        },
      );
    }

    return byLocalPath.values.toList(growable: false)
      ..sort((a, b) => a.remotePath.compareTo(b.remotePath));
  }

  Future<void> _scanDirectory(
    Directory root, {
    required Future<void> Function(File file) onFile,
  }) async {
    try {
      await for (final entity in root.list(
        recursive: false,
        followLinks: false,
      )) {
        final pathLower = entity.path.toLowerCase();
        if (pathLower.endsWith('/android/data') ||
            pathLower.contains('/android/data/') ||
            pathLower.endsWith('/android/obb') ||
            pathLower.contains('/android/obb/')) {
          continue;
        }

        if (isPathExcluded(entity.path, null, const {
          'backups',
          'mob',
          'log',
          'notifications',
          'android',
        }, showHiddenFiles: false)) {
          continue;
        }

        if (entity is File) {
          await onFile(entity);
        } else if (entity is Directory) {
          await _scanDirectory(entity, onFile: onFile);
        }
      }
    } catch (_) {
      // Gracefully ignore directory permission or listing errors
    }
  }

  Future<Directory?> _storageRoot() async {
    final provider = externalStorageDirectoriesProvider;
    final storageDirs = provider == null
        ? await getExternalStorageDirectories()
        : await provider();
    if (storageDirs == null || storageDirs.isEmpty) return null;
    final root = extractRootPath(storageDirs.first.path);
    return root == null ? null : Directory(root);
  }

  Future<String> _identityPath(File file) async {
    return p.normalize(p.absolute(file.path));
  }

  Future<String> _targetDirectory(Map<String, Object?> prefs) async {
    final raw = prefs['backupTargetDirectory'];
    final value = raw is String && raw.trim().isNotEmpty
        ? raw.trim()
        : await _settingsService.defaultBackupTargetDirectory();
    return p.posix.normalize(value).replaceAll(RegExp(r'^/+'), '');
  }

  List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String? _categoryForFile(File file) {
    final path = file.path.toLowerCase();
    if (photoExtensions.any(path.endsWith)) return 'photos';
    if (videoExtensions.any(path.endsWith)) return 'videos';
    if (audioExtensions.any(path.endsWith)) return 'audio';
    if (documentExtensions.any(path.endsWith)) return 'documents';
    return 'other';
  }
}

abstract class SyncApiClient {
  Future<void> createFolder({
    required ServerProfile server,
    required String remotePath,
  });

  Future<void> uploadFile({
    required ServerProfile server,
    required String remotePath,
    required File file,
  });

  Future<bool> fileExists({
    required ServerProfile server,
    required String remotePath,
  });

  Future<Map<String, String>> checkHashes({
    required ServerProfile server,
    required List<String> hashes,
  });
}

class HttpSyncApiClient implements SyncApiClient {
  HttpSyncApiClient({required this.authService, http.Client? client})
    : _client = client ?? http.Client();

  final AuthService authService;
  final http.Client _client;

  @override
  Future<void> createFolder({
    required ServerProfile server,
    required String remotePath,
  }) async {
    final uri = _apiUri(
      server.connectionUrl,
      '/api/folders',
    ).replace(queryParameters: {'scope': 'private', 'path': remotePath});
    final response = await _authorizedRequest(
      server: server,
      send: (token) => _client.post(
        uri,
        headers: {'authorization': 'Bearer $token'},
        body: const [],
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw SyncException('Create folder failed: HTTP ${response.statusCode}');
  }

  @override
  Future<bool> fileExists({
    required ServerProfile server,
    required String remotePath,
  }) async {
    final uri = _apiUri(
      server.connectionUrl,
      '/api/files',
    ).replace(queryParameters: {'scope': 'private', 'path': remotePath});
    final response = await _authorizedRequest(
      server: server,
      send: (token) =>
          _client.head(uri, headers: {'authorization': 'Bearer $token'}),
    );
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, String>> checkHashes({
    required ServerProfile server,
    required List<String> hashes,
  }) async {
    if (hashes.isEmpty) return const {};
    final uri = _apiUri(
      server.connectionUrl,
      '/api/files/check-hashes',
    ).replace(queryParameters: {'scope': 'private'});
    final response = await _authorizedRequest(
      server: server,
      send: (token) => _client.post(
        uri,
        headers: {
          'authorization': 'Bearer $token',
          'content-type': 'application/json',
        },
        body: jsonEncode({'hashes': hashes}),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final existing = decoded['existing'] as Map<String, dynamic>? ?? const {};
      return existing.map((key, value) {
        final path = (value as Map<String, dynamic>)['path'] as String;
        return MapEntry(key, path);
      });
    }
    throw SyncException('Check hashes failed: HTTP ${response.statusCode}');
  }

  @override
  Future<void> uploadFile({
    required ServerProfile server,
    required String remotePath,
    required File file,
  }) async {
    final uri = _apiUri(
      server.connectionUrl,
      '/api/files',
    ).replace(queryParameters: {'scope': 'private', 'path': remotePath});
    final response = await _authorizedStreamRequest(
      server: server,
      send: (token) async {
        final request = http.StreamedRequest('POST', uri)
          ..headers['authorization'] = 'Bearer $token'
          ..headers['content-type'] = 'application/octet-stream'
          ..contentLength = await file.length();

        final responseFuture = _client.send(request);

        try {
          await request.sink.addStream(file.openRead());
        } finally {
          await request.sink.close();
        }

        return responseFuture;
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw SyncException('Upload failed: HTTP ${response.statusCode}');
  }

  Future<http.Response> _authorizedRequest({
    required ServerProfile server,
    required Future<http.Response> Function(String token) send,
  }) async {
    var token = await authService.readAccessToken(server.id);
    if (token == null || token.isEmpty) {
      throw const SyncException('Authentication required');
    }
    var response = await send(token);
    if (response.statusCode != 401) return response;
    await authService.refreshSession(
      serverId: server.id,
      baseUrl: server.connectionUrl,
    );
    token = await authService.readAccessToken(server.id);
    if (token == null || token.isEmpty) {
      throw const SyncException('Authentication required');
    }
    return send(token);
  }

  Future<http.StreamedResponse> _authorizedStreamRequest({
    required ServerProfile server,
    required Future<http.StreamedResponse> Function(String token) send,
  }) async {
    var token = await authService.readAccessToken(server.id);
    if (token == null || token.isEmpty) {
      throw const SyncException('Authentication required');
    }
    var response = await send(token);
    if (response.statusCode != 401) return response;
    await response.stream.drain<void>();
    await authService.refreshSession(
      serverId: server.id,
      baseUrl: server.connectionUrl,
    );
    token = await authService.readAccessToken(server.id);
    if (token == null || token.isEmpty) {
      throw const SyncException('Authentication required');
    }
    return send(token);
  }

  Uri _apiUri(String baseUrl, String path) {
    final raw = baseUrl.trim();
    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final base = Uri.parse(withScheme);
    final basePath = base.path.isEmpty
        ? '/'
        : (base.path.endsWith('/') ? base.path : '${base.path}/');
    return base.replace(path: basePath).resolve(path.substring(1));
  }
}

class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => 'SyncException($message)';
}

class SyncService {
  SyncService({
    required this.scanner,
    required this.apiClient,
    required this.stateStore,
  });

  final SyncFileScanner scanner;
  final SyncApiClient apiClient;
  final SyncStateStore stateStore;

  Future<String> calculateSha256(File file) async {
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;
    return hash.toString();
  }

  Future<SyncRunResult> syncServer(
    ServerProfile server, {
    void Function(String message, double? progress)? onProgress,
  }) async {
    final startedAt = DateTime.now().toUtc();
    var scanned = 0;
    var uploaded = 0;
    var skipped = 0;
    var failed = 0;
    String? message;

    onProgress?.call('Scanning files on device...', null);

    try {
      final candidates = await scanner.scan(server);
      scanned = candidates.length;
      if (candidates.isEmpty) {
        onProgress?.call('No files found to synchronize.', 1.0);
        final result = SyncRunResult(
          status: SyncRunStatus.noFiles,
          scannedFiles: 0,
          uploadedFiles: 0,
          skippedFiles: 0,
          failedFiles: 0,
          startedAt: startedAt,
          finishedAt: DateTime.now().toUtc(),
          message: 'No files selected for synchronization.',
        );
        await stateStore.saveLastResult(server.id, result);
        return result;
      }

      final createdFolders = <String>{};
      final candidatesToHash = <SyncCandidate>[];
      final candidateStats = <SyncCandidate, FileStat>{};
      final candidateLocalPaths = <SyncCandidate, String>{};

      for (final candidate in candidates) {
        final stat = await candidate.file.stat();
        final localPath = p.normalize(p.absolute(candidate.file.path));
        final existing = await stateStore.readRecord(
          server.id,
          localPath,
          candidate.remotePath,
        );
        bool isAlreadySynced = false;
        // Check if file is already matched by local path + size + modified date,
        // and verify it still exists on the server (using its stored remote path, which might be different).
        if (existing != null &&
            existing.sizeBytes == stat.size &&
            existing.modifiedAtMillis ==
                stat.modified.toUtc().millisecondsSinceEpoch) {
          try {
            if (await apiClient.fileExists(
              server: server,
              remotePath: existing.remotePath,
            )) {
              isAlreadySynced = true;
            }
          } catch (_) {
            // If fileExists check fails, assume it needs hash check/upload
          }
        }
        if (isAlreadySynced) {
          skipped++;
          continue;
        }

        candidatesToHash.add(candidate);
        candidateStats[candidate] = stat;
        candidateLocalPaths[candidate] = localPath;
      }

      // Step 2: Compute hashes for candidates that aren't already locally matched
      final hashToCandidate = <String, SyncCandidate>{};
      final candidateToHash = <SyncCandidate, String>{};

      if (candidatesToHash.isNotEmpty) {
        for (var i = 0; i < candidatesToHash.length; i++) {
          final candidate = candidatesToHash[i];
          final filename = p.basename(candidate.file.path);
          onProgress?.call(
            'Calculating checksum (${i + 1}/${candidatesToHash.length}): $filename',
            i / candidatesToHash.length,
          );
          try {
            final sha256Val = await calculateSha256(candidate.file);
            hashToCandidate[sha256Val] = candidate;
            candidateToHash[candidate] = sha256Val;
          } catch (e) {
            // Hashing error, will fail on upload anyway
          }
        }
      }

      // Step 3: Query server for duplicate file hashes
      Map<String, String> existingRemotePaths = const {};
      if (hashToCandidate.isNotEmpty) {
        onProgress?.call('Checking for duplicates on server...', null);
        try {
          existingRemotePaths = await apiClient.checkHashes(
            server: server,
            hashes: hashToCandidate.keys.toList(),
          );
        } catch (_) {
          // If server call fails, fallback to uploading
        }
      }

      // Step 4: Perform upload / skip matching files
      for (var i = 0; i < candidatesToHash.length; i++) {
        final candidate = candidatesToHash[i];
        final filename = p.basename(candidate.file.path);
        final progress = i / candidatesToHash.length;
        onProgress?.call(
          'Syncing (${i + 1}/${candidatesToHash.length}): $filename',
          progress,
        );

        final stat = candidateStats[candidate]!;
        final localPath = candidateLocalPaths[candidate]!;
        final sha256Val = candidateToHash[candidate];

        String? foundRemotePath;
        if (sha256Val != null && sha256Val.isNotEmpty) {
          foundRemotePath = existingRemotePaths[sha256Val];
        }

        if (foundRemotePath != null) {
          // File with this hash already exists on the server!
          // We save the record with the path found on the server, so we skip next time.
          await stateStore.saveRecord(
            server.id,
            SyncFileRecord(
              localPath: localPath,
              remotePath: foundRemotePath,
              sizeBytes: stat.size,
              modifiedAtMillis: stat.modified.toUtc().millisecondsSinceEpoch,
              uploadedAt: DateTime.now().toUtc(),
            ),
          );
          skipped++;
          continue;
        }

        try {
          final remoteFolder = p.posix.dirname(candidate.remotePath);
          if (remoteFolder != '.' && createdFolders.add(remoteFolder)) {
            await _createFolderTree(server, remoteFolder);
          }
          await apiClient.uploadFile(
            server: server,
            remotePath: candidate.remotePath,
            file: candidate.file,
          );
          await stateStore.saveRecord(
            server.id,
            SyncFileRecord(
              localPath: localPath,
              remotePath: candidate.remotePath,
              sizeBytes: stat.size,
              modifiedAtMillis: stat.modified.toUtc().millisecondsSinceEpoch,
              uploadedAt: DateTime.now().toUtc(),
            ),
          );
          uploaded++;
        } on SyncException catch (e) {
          if (e.message == 'Authentication required') rethrow;
          failed++;
          message ??= e.message;
        } catch (e) {
          failed++;
          message ??= e.toString();
        }
      }

      onProgress?.call('Completing synchronization...', 1.0);

      final status = failed > 0
          ? SyncRunStatus.partialFailure
          : SyncRunStatus.success;
      final result = SyncRunResult(
        status: status,
        scannedFiles: scanned,
        uploadedFiles: uploaded,
        skippedFiles: skipped,
        failedFiles: failed,
        startedAt: startedAt,
        finishedAt: DateTime.now().toUtc(),
        message: message,
      );
      await stateStore.saveLastResult(server.id, result);
      return result;
    } on SyncException catch (e) {
      final status = e.message == 'Authentication required'
          ? SyncRunStatus.authRequired
          : SyncRunStatus.failed;
      final result = SyncRunResult(
        status: status,
        scannedFiles: scanned,
        uploadedFiles: uploaded,
        skippedFiles: skipped,
        failedFiles: failed,
        startedAt: startedAt,
        finishedAt: DateTime.now().toUtc(),
        message: e.message,
      );
      await stateStore.saveLastResult(server.id, result);
      return result;
    } catch (e) {
      final result = SyncRunResult(
        status: SyncRunStatus.failed,
        scannedFiles: scanned,
        uploadedFiles: uploaded,
        skippedFiles: skipped,
        failedFiles: failed,
        startedAt: startedAt,
        finishedAt: DateTime.now().toUtc(),
        message: e.toString(),
      );
      await stateStore.saveLastResult(server.id, result);
      return result;
    }
  }

  Future<void> _createFolderTree(
    ServerProfile server,
    String remoteFolder,
  ) async {
    final parts = p.posix.split(remoteFolder).where((part) => part.isNotEmpty);
    var current = '';
    for (final part in parts) {
      current = current.isEmpty ? part : p.posix.join(current, part);
      await apiClient.createFolder(server: server, remotePath: current);
    }
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
