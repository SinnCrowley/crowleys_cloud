import 'dart:async';
import 'dart:io';
import 'package:crowleys_cloud/main.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'smart_thumbnail.dart';
import 'file_item.dart';

enum SortBy { name, date, size, type }

class FileBrowser extends StatefulWidget {
  final FileCategory category;
  final bool isGridView;

  const FileBrowser({
    super.key,
    required this.category,
    required this.isGridView,
  });

  @override
  State<FileBrowser> createState() => FileBrowserState();
}

class FileBrowserState extends State<FileBrowser> {
  bool _isLoading = true;
  String? _error;
  final List<FileItem> _files = [];
  final Set<FileItem> _selectedFiles = {};

  bool get isSelectionMode => _selectedFiles.isNotEmpty;

  // Для режима "All files" — стек навигации по папкам
  final List<Directory> _directoryHistory = [];
  StreamSubscription? _fileStreamSubscription;
  int _operationId = 0;

  String? _tempPath;
  SortBy _sortBy = SortBy.name;
  bool _sortAscending = true;
  String _searchQuery = '';

  // ─── категории, которые грузятся через MediaStore ───────────────────────────
  static const _mediaStoreCategories = {'Photos', 'Videos', 'Audio'};

  @override
  void initState() {
    super.initState();
    _loadSortPreferences();
    _initializeAndLoadFiles();
  }

  @override
  void dispose() {
    _fileStreamSubscription?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Настройки сортировки
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sortBy = SortBy.values[prefs.getInt('sortBy') ?? 0];
      _sortAscending = prefs.getBool('sortAscending') ?? true;
    });
  }

  Future<void> _saveSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortBy', _sortBy.index);
    await prefs.setBool('sortAscending', _sortAscending);
  }

  void setSearchQuery(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
    _initializeAndLoadFiles();
  }

  bool _isMatch(String fileName, String query) {
    if (query.isEmpty) return true;
    final nameLower = fileName.toLowerCase();
    final queryLower = query.toLowerCase();
    
    if (nameLower.contains(queryLower)) return true;

    final queryWords = queryLower.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    if (queryWords.isEmpty) return false;

    int matches = 0;
    for (final word in queryWords) {
      if (nameLower.contains(word)) matches++;
    }
    
    // Если совпало хотя бы 50% слов (но не меньше 1)
    return matches >= (queryWords.length / 2).ceil();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Инициализация и выбор стратегии загрузки
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _initializeAndLoadFiles() async {
    _operationId++;
    final opId = _operationId;
    
    _tempPath = (await getTemporaryDirectory()).path;
    if (opId != _operationId) return;

    if (widget.category.name == 'All files') {
      if (_directoryHistory.isEmpty) {
        // Файловый браузер — прямой обход FS
        final storageDirs = await getExternalStorageDirectories();
        if (opId != _operationId) return;
        
        final rootDir = storageDirs?.first;
        if (rootDir == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final androidDataIndex = rootDir.path.indexOf('/Android/data');
        if (androidDataIndex != -1) {
          final rootPath = rootDir.path.substring(0, androidDataIndex);
          final directory = Directory(rootPath);
          _directoryHistory.add(directory);
        } else {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }
      
      if (_searchQuery.isNotEmpty) {
        _searchRecursively(_directoryHistory.last, opId);
      } else {
        _loadDirectoryFiles(_directoryHistory.last);
      }
    } else if (_mediaStoreCategories.contains(widget.category.name)) {
      // Медиафайлы — MediaStore через photo_manager (мгновенные миниатюры)
      _loadFromMediaStore(widget.category.name, opId);
    } else {
      // Documents, Other — обход FS с фильтром
      _loadByFileWalk(opId);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Стратегия 1: MediaStore (Photos / Videos / Audio)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadFromMediaStore(String category, int opId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _files.clear();
    });

    final perm = await PhotoManager.requestPermissionExtend();
    if (opId != _operationId) return;
    
    if (!perm.isAuth) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final type = switch (category) {
      'Photos' => RequestType.image,
      'Videos' => RequestType.video,
      'Audio'  => RequestType.audio,
      _        => RequestType.common,
    };

    final albums = await PhotoManager.getAssetPathList(
      type: type,
      hasAll: true,
      onlyAll: false,
    );
    if (opId != _operationId) return;

    if (albums.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final allAlbum =
    albums.firstWhere((a) => a.isAll, orElse: () => albums.first);
    final total = await allAlbum.assetCountAsync;

    const pageSize = 2000;

    for (var page = 0; page * pageSize < total; page++) {
      if (opId != _operationId) return;

      final assets = await allAlbum.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      if (opId != _operationId) return;

      final items = assets.map(FileItem.fromAsset).where((item) {
        return _isMatch(item.name, _searchQuery);
      }).toList();

      setState(() {
        _files.addAll(items);
        _files.sort(_compare);
        _isLoading = false; // снимаем лоадер после первой страницы
      });

      // Даём UI отрисоваться перед следующей страницей
      await Future.delayed(Duration.zero);
    }

    if (mounted && opId == _operationId) setState(() => _isLoading = false);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Стратегия 2: Обход FS (Documents / Other)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadByFileWalk(int opId) async {
    if (!mounted) return;
    setState(() { _isLoading = true; _files.clear(); });

    final storageDirs = await getExternalStorageDirectories();
    if (opId != _operationId) return;

    if (storageDirs == null || storageDirs.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final rootPath = _extractRootPath(storageDirs.first.path);
    if (rootPath == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final batch = <FileItem>[];
    const batchSize = 50;

    Future<void> walkDir(Directory dir) async {
      if (opId != _operationId) return;
      
      List<FileSystemEntity> entries;
      try {
        entries = await dir.list(recursive: false).toList();
      } catch (_) {
        return;
      }

      for (final entity in entries) {
        if (opId != _operationId) return;

        if (entity is Directory) {
          if (!_isPathExcluded(entity.path)) {
            await walkDir(entity);
          }
          continue;
        }

        if (entity is! File) continue;
        if (_isPathExcluded(entity.path)) continue;
        if (!_entityMatchesCategory(entity)) continue;
        
        final item = FileItem.fromEntity(entity);
        if (!_isMatch(item.name, _searchQuery)) continue;

        batch.add(item);

        if (batch.length >= batchSize) {
          final snapshot = List<FileItem>.from(batch);
          batch.clear();
          if (opId != _operationId) return;
          setState(() {
            _files.addAll(snapshot);
            _files.sort(_compare);
            _isLoading = false;
          });
          await Future.delayed(Duration.zero);
        }
      }
    }

    await walkDir(Directory(rootPath));

    if (opId != _operationId) return;
    setState(() {
      if (batch.isNotEmpty) _files.addAll(batch);
      _files.sort(_compare);
      _isLoading = false;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Стратегия 3: Директорийный браузер (All files)
  // ═══════════════════════════════════════════════════════════════════════════

  void _loadDirectoryFiles(Directory dir) {
    _fileStreamSubscription?.cancel();
    setState(() {
      _isLoading = true;
      _files.clear();
    });

    final batch = <FileItem>[];
    final stream = dir.list(recursive: false, followLinks: false);

    _fileStreamSubscription = stream.listen(
          (entity) {
        if (!_isPathExcluded(entity.path)) {
          final item = FileItem.fromEntity(entity);
          if (_isMatch(item.name, _searchQuery)) {
            batch.add(item);
          }
        }
      },
      onDone: () {
        if (!mounted) return;
        batch.sort(_compare);
        setState(() {
          _files.addAll(batch);
          _isLoading = false;
        });
      },
      onError: (e) {
        if (mounted) setState(() => _error = e.toString());
      },
    );
  }

  Future<void> _searchRecursively(Directory dir, int opId) async {
    _fileStreamSubscription?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _files.clear();
    });

    final batch = <FileItem>[];
    const batchSize = 50;

    Future<void> walk(Directory d) async {
      if (opId != _operationId) return;

      List<FileSystemEntity> entries;
      try {
        entries = await d.list(recursive: false).toList();
      } catch (_) {
        return;
      }

      for (final entity in entries) {
        if (opId != _operationId) return;
        if (_isPathExcluded(entity.path)) continue;

        final item = FileItem.fromEntity(entity);
        if (_isMatch(item.name, _searchQuery)) {
          batch.add(item);
        }

        if (entity is Directory) {
          await walk(entity);
        }

        if (batch.length >= batchSize) {
          final snapshot = List<FileItem>.from(batch);
          batch.clear();
          if (opId != _operationId) return;
          setState(() {
            _files.addAll(snapshot);
            _files.sort(_compare);
            _isLoading = false;
          });
          await Future.delayed(Duration.zero);
        }
      }
    }

    await walk(dir);

    if (opId != _operationId) return;
    setState(() {
      if (batch.isNotEmpty) _files.addAll(batch);
      _files.sort(_compare);
      _isLoading = false;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Вспомогательные методы
  // ═══════════════════════════════════════════════════════════════════════════

  String? _extractRootPath(String path) {
    final idx = path.indexOf('/Android/data');
    return idx != -1 ? path.substring(0, idx) : null;
  }

  bool _isPathExcluded(String path) {
    const excludedFolders = ['backups', 'mob', 'log', 'notifications'];

    if (_tempPath != null && path.startsWith(_tempPath!)) return true;

    final lower = path.toLowerCase();
    final segments = lower.split('/');

    // Скрытые папки (начинаются с точки)
    if (segments.any((s) => s.startsWith('.') && s.length > 1)) return true;

    // Шумовые папки
    if (excludedFolders.any((f) => segments.contains(f))) return true;

    // /Android/data и /Android/obb — исключаем точечно.
    // /Android/media — разрешаем.
    if (lower.contains('/android/data/') || lower.contains('/android/obb/')) return true;

    return false;
  }

  bool _entityMatchesCategory(FileSystemEntity entity) {
    if (entity is! File) return false;

    const photoExt = [
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.avif', '.heif', '.heic'
    ];
    const videoExt = ['.mp4', '.mkv', '.webm', '.mov', '.avi', '.flv'];
    const audioExt = ['.mp3', '.wav', '.aac', '.m4a', '.ogg', '.flac'];
    const docExt = [
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.csv'
    ];

    final path = entity.path.toLowerCase();

    return switch (widget.category.name) {
      'Photos'    => photoExt.any(path.endsWith),
      'Videos'    => videoExt.any(path.endsWith),
      'Audio'     => audioExt.any(path.endsWith),
      'Documents' => docExt.any(path.endsWith),
      'Other' => () {
        final all = [...photoExt, ...videoExt, ...audioExt, ...docExt];
        return !all.any(path.endsWith);
      }(),
      _ => false,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Навигация
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // Навигация и действия с файлами
  // ═══════════════════════════════════════════════════════════════════════════

  void _onItemTap(FileItem item) {
    if (isSelectionMode) {
      _toggleSelection(item);
    } else if (item.isDirectory) {
      final dir = item.fsEntity as Directory;
      _directoryHistory.add(dir);
      _loadDirectoryFiles(dir);
    } else {
      _openFile(item);
    }
  }

  void _onItemLongPress(FileItem item) {
    _toggleSelection(item);
  }

  void _toggleSelection(FileItem item) {
    setState(() {
      if (_selectedFiles.contains(item)) {
        _selectedFiles.remove(item);
      } else {
        _selectedFiles.add(item);
      }
    });
  }

  Future<void> _openFile(FileItem item) async {
    final filePath = await item.path;
    if (filePath.isEmpty) return;
    
    final ext = item.type;

    const imageExtensions = [
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.avif', '.heif', '.heic'
    ];
    const textExtensions = ['.txt', '.md', '.log', '.csv', '.json'];

    if (imageExtensions.contains(ext)) {
      final imageItems = _files.where((f) => imageExtensions.contains(f.type)).toList();
      final initialIndex = imageItems.indexOf(item);

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewer(
            imageItems: imageItems,
            initialIndex: initialIndex >= 0 ? initialIndex : 0,
          ),
        ),
      );
    } else if (textExtensions.contains(ext)) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextViewer(file: File(filePath)),
        ),
      );
    } else {
      OpenFile.open(filePath);
    }
  }

  void _shareSelectedFiles() async {
    final List<XFile> filesToShare = [];
    for (var item in _selectedFiles) {
      final path = await item.path;
      if (path.isNotEmpty) {
        filesToShare.add(XFile(path));
      }
    }

    if (filesToShare.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: filesToShare));
    }
  }

  void _deleteSelectedFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text('Delete Files?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${_selectedFiles.length} selected items? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var item in _selectedFiles) {
        try {
          if (item.isAsset) {
            // photo_manager не поддерживает прямое удаление через File API легко
            // но мы можем попробовать получить file и удалить его
            final file = await item.asset!.originFile;
            if (file != null && await file.exists()) {
              await file.delete();
            }
          } else if (item.fsEntity != null) {
            if (item.fsEntity is Directory) {
              await item.fsEntity!.delete(recursive: true);
            } else {
              await item.fsEntity!.delete();
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting ${item.name}: $e')),
            );
          }
        }
      }
      setState(() {
        _files.removeWhere((f) => _selectedFiles.contains(f));
        _selectedFiles.clear();
      });
    }
  }

  void clearSelection() {
    setState(() {
      _selectedFiles.clear();
    });
  }

  bool canNavigateBack() =>
      widget.category.name == 'All files' && _directoryHistory.length > 1;

  void navigateBack() {
    if (canNavigateBack()) {
      _directoryHistory.removeLast();
      _loadDirectoryFiles(_directoryHistory.last);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Сортировка
  // ═══════════════════════════════════════════════════════════════════════════

  void _sortFiles() => setState(() => _files.sort(_compare));

  int _compare(FileItem a, FileItem b) {
    // Папки всегда наверху
    if (a.isDirectory && !b.isDirectory) return -1;
    if (!a.isDirectory && b.isDirectory) return 1;

    final int result = switch (_sortBy) {
      SortBy.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      SortBy.date => a.modifiedDate.compareTo(b.modifiedDate),
      SortBy.size => a.size.compareTo(b.size),
      SortBy.type => a.type.compareTo(b.type),
    };

    return _sortAscending ? result : -result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildHeaderControls(),
            Expanded(child: _buildFileView()),
          ],
        ),
        if (isSelectionMode) _buildBottomActionBar(),
      ],
    );
  }

  Widget _buildHeaderControls() {
    if (isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
        child: Row(
          children: [
            Checkbox(
              value: _selectedFiles.length == _files.length && _files.isNotEmpty,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (bool? isChecked) {
                setState(() {
                  if (isChecked ?? false) {
                    _selectedFiles.addAll(_files);
                  } else {
                    _selectedFiles.clear();
                  }
                });
              },
            ),
            Text(
              '${_selectedFiles.length} selected',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _selectedFiles.clear();
                });
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.sort, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<SortBy>(
                    value: _sortBy,
                    dropdownColor: const Color(0xFF333333),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                    items: SortBy.values.map((v) {
                      final name =
                          v.name[0].toUpperCase() + v.name.substring(1);
                      return DropdownMenuItem(value: v, child: Text(name));
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _sortBy = v);
                      _sortFiles();
                      _saveSortPreferences();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              splashRadius: 20,
              icon: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() => _sortAscending = !_sortAscending);
                _sortFiles();
                _saveSortPreferences();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: const Color(0xFF222222),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          //mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: TextButton.icon(
              icon: const Icon(Icons.upload, color: Colors.white70),
              label:
                  const Text('Upload', style: TextStyle(color: Colors.white)),
              onPressed: () {
                // TODO: Implement upload
              },
            )),
            Expanded(child: TextButton.icon(
              icon: const Icon(Icons.delete, color: Colors.white70),
              label:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: _deleteSelectedFiles,
            )),
            Expanded(child: TextButton.icon(
              icon: const Icon(Icons.share, color: Colors.white70),
              label: const Text('Share', style: TextStyle(color: Colors.white)),
              onPressed: _shareSelectedFiles,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFileView() {
    if (_isLoading && _files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_files.isEmpty) {
      return const Center(child: Text('No files found.'));
    }

    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      thickness: 8.0,
      radius: const Radius.circular(4.0),
      child: widget.isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _files.length,
      itemBuilder: (_, i) => _buildGridItem(_files[i]),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      itemBuilder: (_, i) => _buildListItem(_files[i]),
    );
  }

  Widget _buildGridItem(FileItem item) {
    final isSelected = _selectedFiles.contains(item);
    return InkWell(
      key: ValueKey(item.pathSync),
      onTap: () => _onItemTap(item),
      onLongPress: () => _onItemLongPress(item),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: SmartThumbnail(item: item)),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(color: Colors.white70),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle, color: Colors.white, size: 32),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListItem(FileItem item) {
    final isSelected = _selectedFiles.contains(item);
    return Padding(
      key: ValueKey(item.pathSync),
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: SmartThumbnail(item: item, isList: true),
        title: Text(item.name, style: const TextStyle(color: Colors.white70)),
        trailing: isSelectionMode
            ? Checkbox(
                value: isSelected,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (_) => _toggleSelection(item),
              )
            : IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onPressed: () => _showContextMenu(context, item),
              ),
        onTap: () => _onItemTap(item),
        onLongPress: () => _onItemLongPress(item),
        tileColor: isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : const Color(0xFF333333),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 1)
              : BorderSide.none,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, FileItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF333333),
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.upload, color: Colors.white70),
            title: const Text('Upload', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.white70),
            title: const Text('Delete', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedFiles.add(item);
                _deleteSelectedFiles();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white70),
            title: const Text('Share', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedFiles.add(item);
                _shareSelectedFiles();
              });
            }
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ImageViewer
// ═══════════════════════════════════════════════════════════════════════════

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

class _ImageViewerState extends State<ImageViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _isUiVisible = true;
  int _pointerCount = 0;

  // Для кастомного свайпа вверх
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

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_pointerCount > 1) return;

    setState(() {
      _dragOffset += details.delta.dy;
      _isDraggingUp = _dragOffset < 0;
    });

    // Скрываем UI сразу при начале свайпа вверх
    if (_isDraggingUp && _isUiVisible) {
      setState(() => _isUiVisible = false);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    // Если свайпнули вверх достаточно сильно или далеко — закрываем
    if ((_dragOffset < -150 || velocity < -800) && _isDraggingUp) {
      Navigator.of(context).pop();
    } else {
      // Отмена — возвращаем всё на место
      setState(() {
        _dragOffset = 0.0;
        _isDraggingUp = false;
        _isUiVisible = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages(_currentIndex);
  }

  void _precacheImages(int index) {
    // Кэшируем текущее, следующее и предыдущее изображения
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

  void _shareCurrentFile() async {
    final item = widget.imageItems[_currentIndex];
    final path = await item.path;
    if (path.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    }
  }

  void _deleteCurrentFile() async {
    final item = widget.imageItems[_currentIndex];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
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
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
        if (mounted) {
          Navigator.of(context).pop(true);
        }
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
            if (!_isDraggingUp) {
              setState(() => _isUiVisible = !_isUiVisible);
            }
          },
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Stack(
            children: [
              // Основное изображение с трансформацией
              Transform.translate(
                offset: Offset(0, _dragOffset),
                child: Opacity(
                  opacity: (_isDraggingUp ? (1 + _dragOffset / 400).clamp(0.0, 1.0) : 1.0),
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
                              thumbnailSize: const ThumbnailSize.square(1280),
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

              // Top Bar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                top: (_isUiVisible && !_isDraggingUp) ? 0 : -140,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          widget.imageItems[_currentIndex].name,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Bar
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
                      _ActionButton(icon: Icons.upload, label: 'Upload', onPressed: () {}),
                      _ActionButton(icon: Icons.delete, label: 'Delete', onPressed: _deleteCurrentFile),
                      _ActionButton(icon: Icons.share, label: 'Share', onPressed: _shareCurrentFile),
                    ],
                  ),
                ),
              ),

              // Затемнение при свайпе (как в Google Фото)
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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TextViewer
// ═══════════════════════════════════════════════════════════════════════════

class TextViewer extends StatelessWidget {
  final File file;

  const TextViewer({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(p.basename(file.path)),
        backgroundColor: const Color(0xFF333333),
        surfaceTintColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
        elevation: 0.0,
      ),
      body: FutureBuilder<String>(
        future: file.readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error reading file: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                snapshot.data ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
