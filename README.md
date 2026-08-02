# Crowley's Cloud — Flutter Mobile Client

A feature-rich, high-performance Flutter mobile application for **Crowley's Cloud**. It supports managing multiple server profiles, dynamic browsing, secure token storage, media thumbnail caching, background directory synchronization, and Protocol Buffers data transfer.

---

## Core Features

1. **Multi-Server Profile Management**:
   - Add, store, and switch connection settings for multiple independent Crowley's Cloud server hosts.
   - Server-level session state check.

2. **File Browser (Local & Remote)**:
   - Dynamic directory navigation.
   - Category filtering (All, Images, Videos, Audio, Documents).
   - Multi-selection toolbar for batch downloads, uploads, deletions, and sharing.
   - Real-time file searching (recursive on the server).
   - Sorting options (by name, size, modification date, and type) in ascending/descending orders.

3. **Authentication & Security**:
   - Standard user registration and login forms.
   - Encrypted token storage in the device's secure enclave (Keychain/Keystore) via `flutter_secure_storage`.
   - Biometric authentication (Fingerprint, FaceID) via `local_auth` for quick login.
   - Automated JWT session refresh handlers.

4. **Background Directory Synchronization**:
   - Set up custom directories on the mobile device to sync automatically to specified server paths.
   - Uses `Workmanager` to schedule tasks based on system conditions (e.g., charging, Wi-Fi connected).
   - Avoids redundant uploads by keeping a local SQLite index database (`FileSyncStateStore`) to compare file hashes, sizes, and last modified dates.

5. **Advanced Transfers & Previews**:
   - Queue-based upload and download streams via a centralized `TransferManager`.
   - Support for chunked file uploading to resume interrupted transfers.
   - Local on-the-fly thumbnail generation for video files, and remote thumbnail previews for images and videos.
   - Custom thematic text viewer (`TextViewer`) supporting dark, light, and custom settings themes.

6. **System Interoperability**:
   - Standard sharing sheet integration (`share_plus`) to send links or files.
   - Background transfer notifications via `flutter_local_notifications`.
   - Native document opening via `open_file`.

---

## Project Directory Structure

```
lib/
├── main.dart                       # App entry point, background worker bootstrap, cache init
├── app_constants.dart              # Core layout styling colors, constants, and extensions
├── app_settings_service.dart       # Local user preferences (theme, sync intervals, limits)
├── app_theme.dart                  # Light, dark, and user-custom theme definitions
├── auth_service.dart               # Registration, login, token refresh, and account erasure
├── biometric_auth_service.dart     # Device biometrics (local_auth wrapper)
├── cache_service.dart              # SQLite-based metadata cache and directory listing stores
├── file_browser_controller.dart    # Controller handling state transitions for local files
├── server_browser_controller.dart  # Controller handling state transitions for remote files
├── server_file_item.dart           # Unified data model for directories and files
├── server_profile.dart             # Connection model for server configurations
├── sync_scheduler.dart             # Workmanager tasks registers and timing triggers
├── sync_service.dart               # File sync comparisons and networking operations
├── thumbnail_service.dart          # Local cache manager for file/video thumbnails
├── transfer_manager.dart           # File transfer queue manager (uploads & downloads)
├── shared/
│   ├── proto/                      # Generated Protobuf Dart classes
│   │   ├── dir_entry.pb.dart       # DirEntry structures
│   │   └── ...
│   ├── utils/
│   │   ├── authenticated_http_client.dart # Client wrapper for auth header attachments & retries
│   │   ├── file_icon_utils.dart           # Maps file extensions to icons & theme colors
│   │   ├── file_type_utils.dart           # Checks file extension category types
│   │   └── url_utils.dart                 # URL sanitation helpers
│   └── viewers/
│       └── text_viewer.dart        # Custom viewer widget for text-based files
test/                               # Dart / Flutter unit and widget tests
```

---

## Development & Build Commands

Ensure you have the [Flutter SDK installed](https://docs.flutter.dev/get-started/install).

### 1. Install Dependencies
Installs packages from `pubspec.yaml`:
```bash
flutter pub get
```

### 2. Run App (Debug Mode)
Launches the mobile app on a connected emulator, simulator, or physical device:
```bash
flutter run
```

### 3. Static Code Analysis
Run Linter checks to verify analysis options compliance (`analysis_options.yaml`):
```bash
flutter analyze
```

### 4. Code Formatting
Format Dart codebase to standard styling rules:
```bash
dart format lib test
```

### 5. Running Tests
Executes the comprehensive Dart/Flutter unit and widget tests:
```bash
flutter test
```

---

## Protobuf Data Serialization

To minimize CPU parsing cycles and network payload size, the client communicates with directory and trash listings using **Protocol Buffers**.

If you make modifications to the communication contract in the `proto/` directory:
1. Ensure the `protoc` compiler is installed.
2. Globally activate the Dart compiler plugin (if not already done):
   ```bash
   dart pub global activate protoc_plugin
   ```
3. Run the generation script from the project root:
   ```bash
   ./scripts/generate_proto.sh
   ```
This updates the serialization files under `lib/shared/proto/`. The HTTP client will automatically send the header `Accept: application/x-protobuf` when listing remote directories, parsing raw binary streams with close-to-zero memory overhead.

---

## Security Highlights

- **OS Secure Storage**: API tokens and login passwords are encrypted and persisted using the Android KeyStore and iOS Keychain. No plaintext credentials touch the filesystem.
- **Biometric Lock**: When enabled, the app locks token generation interfaces until fingerprint/face scans are completed successfully.
- **Token Rotation**: The client automatically requests new JWT access tokens using its refresh tokens without interrupting user actions.

---

## License

**Crowley's Cloud** is open-source software licensed under the [GNU Affero General Public License v3.0 (AGPLv3)](file:///home/crowley/Projects/crowleys_cloud/LICENSE).

---

## Third-Party Software & Licenses

This project relies on open-source frameworks and libraries:

### C++ Backend Server
- **Drogon Web Framework** (MIT)
- **OpenSSL** (Apache License 2.0)
- **SQLite3** (Public Domain)
- **ZLIB** (zlib License)
- **Google Protocol Buffers** (BSD-3-Clause)

### Flutter Mobile Client
- **Flutter SDK** (`flutter`, `flutter_test`, `flutter_lints`) (BSD-3-Clause)
- **permission_handler**, **video_thumbnail_plus**, **workmanager**, **open_file**, **flutter_launcher_icons**, **flutter_native_splash** (MIT)
- **path_provider**, **path**, **shared_preferences**, **flutter_secure_storage**, **http**, **crypto**, **local_auth**, **protobuf**, **fixnum**, **share_plus**, **url_launcher**, **flutter_local_notifications** (BSD-3-Clause)
- **photo_manager_image_provider**, **photo_manager** (Apache 2.0)

For full copyright notices and complete license texts for each dependency, see [THIRD_PARTY_LICENSES.md](file:///home/crowley/Projects/crowleys_cloud/THIRD_PARTY_LICENSES.md).


