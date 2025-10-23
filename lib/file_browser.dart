import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:crowleys_cloud/main.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

enum SortBy {
  name,
  date,
  size,
  type,
}

class FileBrowser extends StatefulWidget {
  final FileCategory category;
  final bool isGridView;

  const FileBrowser({super.key, required this.category, required this.isGridView});

  @override
  State<FileBrowser> createState() => FileBrowserState();
}

class FileBrowserState extends State<FileBrowser> {
  final List<FileSystemEntity> _files = [];
  bool _isLoading = true;
  String? _error;
  final List<Directory> _directoryHistory = [];
  StreamSubscription? _fileStreamSubscription;
  String? _tempPath;
  final _thumbnailCache = <String, Future<Uint8List?>>{};
  SortBy _sortBy = SortBy.name;
  bool _sortAscending = true;

  final _excludedFolders = const [
    'backups',
    'Mob',
    'log',
    'Notifications'
  ];

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

  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
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

  Future<void> _initializeAndLoadFiles() async {
    _tempPath = (await getTemporaryDirectory()).path;
    if (widget.category.name == 'All files') {
      final storageDirs = await getExternalStorageDirectories();
      final rootDir = storageDirs?.first;
      if (rootDir != null) {
        var path = rootDir.path;
        var androidDataIndex = path.indexOf('/Android/data');
        if (androidDataIndex != -1) {
          final rootPath = path.substring(0, androidDataIndex);
          final directory = Directory(rootPath);
          _directoryHistory.add(directory);
          _loadDirectoryFiles(directory);
        }
      }
    } else {
      _loadAllFilesByCategory();
    }
  }

  bool _isPathExcluded(String path) {
    if (_tempPath != null && path.startsWith(_tempPath!)) {
      return true;
    }
    final lowerPath = path.toLowerCase();

    final pathSegments = lowerPath.split('/');
    if (pathSegments.any((segment) => segment.startsWith('.') && segment.length > 1)) {
      return true;
    }
    if (_excludedFolders.any((folder) => lowerPath.contains('/$folder/'))) {
      return true;
    }
    if (lowerPath.contains('/android/') && !lowerPath.contains('/android/media/')) {
      return true;
    }

    return false;
  }

  void _loadDirectoryFiles(Directory dir) {
    _fileStreamSubscription?.cancel();
    setState(() {
      _isLoading = true;
      _files.clear();
    });

    final stream = dir.list(recursive: false, followLinks: false);
    _fileStreamSubscription = stream.listen(
      (entity) {
        if (!_isPathExcluded(entity.path)) {
          _insertSorted(entity);
        }
      },
      onDone: () => setState(() => _isLoading = false),
      onError: (e) => setState(() => _error = e.toString()),
    );
  }

  void _loadAllFilesByCategory() async {
    setState(() {
      _isLoading = true;
      _files.clear();
    });

    final storageDirs = await getExternalStorageDirectories();
    if (storageDirs == null) return;

    final streams = StreamGroup<FileSystemEntity>();

    for (var dir in storageDirs) {
      var path = dir.path;
      var androidDataIndex = path.indexOf('/Android/data');
      if (androidDataIndex != -1) {
        final rootPath = path.substring(0, androidDataIndex);
        final root = Directory(rootPath);
        if (await root.exists()) {
          streams.add(root.list(recursive: true, followLinks: false));
        }
      }
    }

    _fileStreamSubscription = streams.stream.listen(
      (entity) {
        if (!_isPathExcluded(entity.path) && _entityMatchesCategory(entity)) {
          _insertSorted(entity);
        }
      },
      onDone: () => setState(() => _isLoading = false),
      onError: (e) {},
    );
  }

  bool _entityMatchesCategory(FileSystemEntity entity) {
    if (entity is! File) return false;

    const photoExt = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.avif', '.heif', '.heic'];
    const videoExt = ['.mp4', '.mkv', '.webm', '.mov', '.avi', '.flv'];
    const audioExt = ['.mp3', '.wav', '.aac', '.m4a', '.ogg', '.flac'];
    const docExt = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
      '.csv'
    ];

    final path = entity.path.toLowerCase();
    switch (widget.category.name) {
      case 'Photos':
        return photoExt.any((ext) => path.endsWith(ext));
      case 'Videos':
        return videoExt.any((ext) => path.endsWith(ext));
      case 'Audio':
        return audioExt.any((ext) => path.endsWith(ext));
      case 'Documents':
        return docExt.any((ext) => path.endsWith(ext));
      case 'Other':
        final allKnownExt = [...photoExt, ...videoExt, ...audioExt, ...docExt];
        return !allKnownExt.any((ext) => path.endsWith(ext));
      default:
        return false;
    }
  }

  void _onEntityTap(FileSystemEntity entity) {
    if (entity is Directory) {
      _directoryHistory.add(entity);
      _loadDirectoryFiles(entity);
    }
  }

  bool canNavigateBack() {
    return widget.category.name == 'All files' && _directoryHistory.length > 1;
  }

  void navigateBack() {
    if (canNavigateBack()) {
      _directoryHistory.removeLast();
      _loadDirectoryFiles(_directoryHistory.last);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSortControls(),
        Expanded(
          child: _buildFileView(),
        ),
      ],
    );
  }

  Widget _buildSortControls() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(8.0),
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
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    items: SortBy.values.map((SortBy value) {
                      String name = value.name[0].toUpperCase() + value.name.substring(1);
                      return DropdownMenuItem<SortBy>(
                        value: value,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (SortBy? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _sortBy = newValue;
                          _sortFiles();
                          _saveSortPreferences();
                        });
                      }
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
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: IconButton(
              splashRadius: 20,
              icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                  _sortFiles();
                  _saveSortPreferences();
                });
              },
            ),
          ),
        ],
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

    if (_files.isEmpty && !_isLoading) {
      return const Center(child: Text('No files found.'));
    }

    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      child: widget.isGridView ? _buildGridView() : _buildListView(),
    );
  }

  void _insertSorted(FileSystemEntity entity) {
    int index = _files.indexWhere((e) => _compare(entity, e) < 0);
    if (index == -1) {
      index = _files.length;
    }
    if (mounted) {
      setState(() {
        _files.insert(index, entity);
      });
    }
  }

  void _sortFiles() {
    _files.sort(_compare);
  }

  int _compare(FileSystemEntity a, FileSystemEntity b) {
    int result;
    if (a is Directory && b is! Directory) {
      result = -1;
    } else if (a is! Directory && b is Directory) {
      result = 1;
    } else {
      switch (_sortBy) {
        case SortBy.name:
          result = p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
          break;
        case SortBy.date:
          result = b.statSync().modified.compareTo(a.statSync().modified);
          break;
        case SortBy.size:
          result = (b is File ? b.lengthSync() : -1)
              .compareTo(a is File ? a.lengthSync() : -1);
          break;
        case SortBy.type:
          result = p.extension(a.path).toLowerCase().compareTo(p.extension(b.path).toLowerCase());
          break;
      }
    }
    return _sortAscending ? result : -result;
  }

  GridView _buildGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) => _buildGridItem(_files[index]),
      padding: const EdgeInsets.all(16),
    );
  }

  ListView _buildListView() {
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) => _buildListItem(_files[index]),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildGridItem(FileSystemEntity entity) {
    return InkWell(
      key: ValueKey(entity.path),
      onTap: () => _onEntityTap(entity),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildThumbnail(entity),
          ),
          const SizedBox(height: 8),
          Text(
            p.basename(entity.path),
            style: const TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(FileSystemEntity entity) {
    return Padding(
      key: ValueKey(entity.path),
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildThumbnail(entity, isList: true),
        title: Text(p.basename(entity.path),
            style: const TextStyle(color: Colors.white70)),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          onPressed: () => _showContextMenu(context, entity),
        ),
        onTap: () => _onEntityTap(entity),
        tileColor: const Color(0xFF333333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildThumbnail(FileSystemEntity entity, {bool isList = false}) {
    final double size = isList ? 50.0 : 120.0;
    if (entity is Directory) {
      return Icon(Icons.folder, color: const Color(0xFFfa5252), size: size);
    }
    final file = entity as File;
    final fileName = file.path.toLowerCase();

    if (fileName.endsWith('.jpg') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.heic') ||
        fileName.endsWith('.heif') ||
        fileName.endsWith('.avif') ||
        fileName.endsWith('.webp') ||
        fileName.endsWith('.gif') ||
        fileName.endsWith('.bmp')) {
      return _ImageThumbnail(
        key: ValueKey(file.path),
        file: file,
        size: size,
      );
    } else if (fileName.endsWith('.mp4') ||
        fileName.endsWith('.mov') ||
        fileName.endsWith('.avi') ||
        fileName.endsWith('.mkv') ||
        fileName.endsWith('.webm') ||
        fileName.endsWith('.flv')) {
      return _VideoThumbnail(
        key: ValueKey(file.path),
        videoPath: file.path,
        size: size,
        cache: _thumbnailCache,
      );
    } else {
      return Icon(Icons.insert_drive_file, color: const Color(0xFFfa5252), size: size);
    }
  }

  void _showContextMenu(BuildContext context, FileSystemEntity entity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF333333),
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.upload, color: Colors.white70),
              title: const Text('Upload', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white70),
              title: const Text('Rename', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white70),
              title: const Text('Delete', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final File file;
  final double size;

  const _ImageThumbnail({Key? key, required this.file, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.file(
        file,
        width: size,
        height: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: (size * 2).toInt(), // Cache a higher-res version
        gaplessPlayback: true,
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String videoPath;
  final double size;
  final Map<String, Future<Uint8List?>> cache;

  const _VideoThumbnail({
    super.key, // Use key from parent
    required this.videoPath,
    required this.size,
    required this.cache,
  });

  @override
  __VideoThumbnailState createState() => __VideoThumbnailState();
}

class __VideoThumbnailState extends State<_VideoThumbnail> {
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.cache.putIfAbsent(
      widget.videoPath,
      () => VideoThumbnail.thumbnailData(
        video: widget.videoPath,
        imageFormat: ImageFormat.PNG,
        maxWidth: (widget.size * 2).toInt(),
        quality: 100, // Max quality
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.memory(
              snapshot.data!,
              width: widget.size,
              height: double.infinity,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
              child: Icon(Icons.error, color: Colors.red, size: widget.size / 2));
        } else {
          return Container(
            width: widget.size,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
                child: Icon(Icons.movie,
                    color: Colors.white54, size: widget.size / 2)),
          );
        }
      },
    );
  }
}
