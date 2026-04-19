import 'dart:async';
import 'package:crowleys_cloud/file_browser.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'thumbnail_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThumbnailService.instance.init();
  runApp(const CrowleysCloudApp());
}

class CrowleysCloudApp extends StatelessWidget {
  const CrowleysCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crowley\'s Cloud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF222222),
        primaryColor: const Color(0xFFfa5252),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFfa5252),
          secondary: Color(0xFFfa5252),
          surface: Color(0xFF333333),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class FileCategory {
  final String name;
  final IconData icon;
  const FileCategory(this.name, this.icon);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTabIndex = 0;
  bool _isGridView = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FileBrowserState> _fileBrowserKey = GlobalKey<FileBrowserState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  FileCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});        // ← это заставит кнопку появляться/исчезать сразу
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(() {
      setState(() {});
    });
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_fileBrowserKey.currentState != null) {
        _fileBrowserKey.currentState!.setSearchQuery(query);
      } else {
        // Если мы на главном экране категорий, можно просто обновить UI
        setState(() {});
      }
    });
  }

  void _onCategorySelected(FileCategory category) async {
    if (_selectedTabIndex != 0) return;

    final permissionGranted = await _requestPermission(category);
    if (permissionGranted) {
      _searchController.clear();
      setState(() {
        _selectedCategory = category;
      });
    }
  }

  void _handleBack() {
    final fileBrowserState = _fileBrowserKey.currentState;
    if (fileBrowserState != null && fileBrowserState.isSelectionMode) {
      fileBrowserState.clearSelection();
    } else if (fileBrowserState?.canNavigateBack() ?? false) {
      fileBrowserState?.navigateBack();
    } else {
      _searchController.clear();
      setState(() {
        _selectedCategory = null;
      });
    }
  }

  Future<bool> _requestPermission(FileCategory category) async {
    Permission permission;
    bool isManageExternalStorage = false;

    switch (category.name) {
      case 'Photos':
        permission = Permission.photos;
        break;
      case 'Videos':
        permission = Permission.videos;
        break;
      case 'Audio':
        permission = Permission.audio;
        break;
      default:
        permission = Permission.manageExternalStorage;
        isManageExternalStorage = true;
        break;
    }

    var status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
      if (isManageExternalStorage && !status.isGranted) {
        await openAppSettings();
        status = await permission.status;
      }
    }
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: _selectedCategory == null,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBack();
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              backgroundColor: const Color(0xFF333333),
          surfaceTintColor: const Color(0xFF333333),
          elevation: 0,
          leading: _selectedCategory != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _handleBack,
                )
              : IconButton(
                  iconSize: 28,
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                ),
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54),
                const SizedBox(width: 8),

                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                // Кнопка очистки
                if (_searchController.text.isNotEmpty)
                  //const Icon(Icons.close, color: Colors.white38, size: 20),
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: const Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.grid_view : Icons.list,
                color: const Color(0xFFfa5252),
              ),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
            IconButton(
              iconSize: 28,
              icon: const Icon(Icons.account_circle, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: _buildBody(),
        drawer: _buildDrawer(),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    ),
    );
  }

  Widget _buildBody() {
    if (_selectedCategory == null) {
      return _buildCategoryView();
    } else {
      return FileBrowser(
        key: _fileBrowserKey,
        category: _selectedCategory!,
        isGridView: _isGridView,
      );
    }
  }

  Widget _buildCategoryView() {
    final query = _searchController.text.toLowerCase();
    final List<FileCategory> allCategories = const [
      FileCategory('All files', Icons.folder),
      FileCategory('Photos', Icons.photo),
      FileCategory('Videos', Icons.videocam),
      FileCategory('Audio', Icons.audiotrack),
      FileCategory('Documents', Icons.description),
      FileCategory('Other', Icons.insert_drive_file),
    ];

    final categories = allCategories.where((c) => c.name.toLowerCase().contains(query)).toList();

    if (_isGridView) {
      return GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: categories.map((c) => _buildCategoryItem(c)).toList(),
      );
    } else {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: categories.map((c) => _buildCategoryListItem(c)).toList(),
      );
    }
  }

  Widget _buildCategoryItem(FileCategory category) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onCategorySelected(category),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: const Color(0xFFfa5252), size: 42),
            const SizedBox(height: 8),
            Text(category.name, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryListItem(FileCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(category.icon, color: const Color(0xFFfa5252)),
        title: Text(category.name, style: const TextStyle(color: Colors.white70)),
        tileColor: const Color(0xFF333333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => _onCategorySelected(category),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF333333),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFfa5252)),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Crowley\'s Cloud',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
          _buildDrawerItem(Icons.access_time, 'Recent'),
          _buildDrawerItem(Icons.group, 'Shared with you'),
          _buildDrawerItem(Icons.upload_file, 'Shared by you'),
          _buildDrawerItem(Icons.delete, 'Trash'),
          const Spacer(),
          _buildDrawerItem(Icons.settings, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {},
      tileColor: Colors.transparent,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      color: const Color(0xFF333333),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomTab(0, Icons.folder, 'Local'),
          _buildBottomTab(1, Icons.cloud, 'Cloud'),
        ],
      ),
    );
  }

  Widget _buildBottomTab(int index, IconData icon, String label) {
    final isActive = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _selectedTabIndex = index;
          _selectedCategory = null;
          _searchController.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: isActive
              ? const Color(0xFFfa5252).withValues(alpha: 0.1)
              : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? const Color(0xFFfa5252) : Colors.white70),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFFfa5252) : Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
