# Crowley's Cloud Server

A high-performance, low-latency, and resource-efficient cloud storage backend built with the C++ **Drogon** web framework, **SQLite3**, and **Protocol Buffers**.

---

## Technical Stack & Architecture

- **Web Framework:** [Drogon](https://github.com/drogonframework/drogon) (C++20, asynchronous event-driven network engine)
- **Database Engine:** Embedded SQLite3 (handles users, file indexing, trash, and shares)
- **Serialization:** Protocol Buffers over HTTP (`application/x-protobuf`) for directories/trash listings, falling back to JSON
- **Cryptographic Operations:** OpenSSL (SHA-256 file hashing, AES-256-CBC local file encryption)
- **Compression:** ZLIB (CRC32 calculations & raw zip archives stream compiling)
- **Image Processing:** LibWebP (high-efficiency WebP thumbnail encoding and decoding) & stb (image decoding and resizing)

---

## Prerequisites

To build and run the server, ensure your Linux system has the following installed:

- **Compiler:** GCC (version >= 11) or Clang (version >= 13) supporting C++20
- **Build Tool:** CMake (version >= 3.16)
- **System Libraries:**
  - OpenSSL (development headers)
  - SQLite3 (development headers)
  - ZLIB (development headers)
  - Protocol Buffers (v3 compiler `protoc` and libraries)
  - PkgConfig (required to link Protobuf & Abseil dependencies)
  - JsonCpp (development headers for Drogon JSON routing)
  - UUID (development headers for Drogon session UUIDs)
  - LibWebP (development headers for WebP thumbnail generation)

### On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake libssl-dev libsqlite3-dev zlib1g-dev protobuf-compiler libprotobuf-dev pkg-config libjsoncpp-dev uuid-dev libwebp-dev ffmpeg
```

---

## Compilation and Running

The project utilizes CMake to configure and build. Protobuf code generation is hooked directly into the CMake compilation pipeline.

1. **Configure the build:**
   ```bash
   cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
   ```
2. **Compile the executable:**
   ```bash
   cmake --build build -j$(nproc)
   ```
3. **Build the Web Client (Svelte SPA):**
   ```bash
   cd web
   npm install
   npm run build
   cd ..
   ```
   This compiles the lightweight web interface into `./public/` (`index.html`, CSS, and JS bundle).

4. **Run the server:**
   The server expects a configuration file path as an argument. By default, it will search for `config/config.json` and serve both API routes and static web assets on `http://localhost:8080`.
   ```bash
   ./build/crowleys_cloud_server
   ```

---

## Web Client Architecture (`server/web`)

The web interface is built with **Svelte 4 + Vite** and uses pure Vanilla CSS and CSS custom variables to achieve a lightweight footprint (~28 KB gzipped) and visual parity with the Flutter mobile application.

### Key Features:
- **Zero-Dependency API Client:** Direct native `fetch` requests with transparent JWT refresh token rotation (`/api/refresh`).
- **Responsive Theme Engine:** Identical dark mode (`#1E1E1E`/`#2C2C2C`), light mode (`#F4F5F8`/`#FFFFFF`), and accent color presets (`#FA5252`).
- **Desktop UX & Drag-and-Drop Uploader:** Dragging external OS files/folders into the browser triggers background batch uploads with live progress.
- **Drag-and-Drop File Moving:** Drag files or multi-selected batches into subfolder targets or parent directory `..` with floating cursor badge (`📁 Moving N items`) and confirmation dialog.
- **Embedded Media & Document Previews:** Native HTML5 `<iframe>` preview for PDF files, photo gallery viewer, audio playback, video streaming, and source code viewer.
- **Icon & Visual Parity:** Extension icon resolution (`picture_as_pdf`, `description`, `table_chart`, `slideshow`, `folder_zip`, `article`) matching the Flutter client.
- **Context Menus & Actions:** Right-click actions for download, shared link creation, rename, folder creation, and moving to trash.
- **Trash Manager:** Deleted file browser with item restore and permanent purge functions.

---

## Configuration (`config.json`)

Configuration settings are loaded from `server/config/config.json`. Below is a breakdown of all parameters:

| Parameter Key | Type | Example Value | Description |
| :--- | :---: | :--- | :--- |
| `host` | String | `"0.0.0.0"` | IP address the HTTP server binds to (`0.0.0.0` listens on all interfaces). |
| `port` | Number | `8080` | TCP port for incoming HTTP traffic. |
| `storage_root` | String | `"./storage"` | Local directory where physical user files are saved. |
| `db_path` | String | `"./data/server.sqlite3"` | File path to the SQLite3 database. |
| `temp_upload_dir` | String | `"./uploads"` | Directory used for temporary HTTP upload streams. |
| `public_dir` | String | `"./public"` | Directory path containing static web client assets (Svelte SPA build & static HTML/JS/CSS). |
| `jwt_secret` | String | `""` | Generated once into the local config on a fresh installation; signs access tokens. |
| `upload_limit_bytes` | Number | `10737418240` | Maximum allowed size of an uploaded file in bytes (e.g., 10 GB). |
| `rate_limit_per_minute` | Number | `10` | IP-based request threshold per minute for critical auth endpoints. |
| `access_token_ttl_seconds` | Number | `86400` | Expiry duration for JWT Access Tokens. |
| `refresh_token_ttl_seconds`| Number | `7776000` | Expiry duration for database-backed Refresh Tokens. |
| `log_dir` | String | `"./logs"` | Destination directory for server log files. |
| `log_level` | String | `"INFO"` | Minimum logging verbosity: `DEBUG`, `INFO`, `WARN`, `ERROR`. |
| `access_log_enabled` | Boolean | `true` | Toggle logging of every incoming HTTP request. |
| `video_thumbs_enabled` | Boolean | `true` | Enable on-the-fly video frame thumbnail extraction using FFmpeg. |
| `ffmpeg_binary` | String | `"ffmpeg"` | System path to the `ffmpeg` executable. |
| `log_retention_days` | Number | `30` | Automated rotation and deletion period for server logs. |
| `hash_files` | Boolean | `true` | If `true`, enables **Hashed Storage Layout** (files stored on disk by SHA-256 hash). |
| `encryption_key` | String | `""` | Generated once for a fresh installation; used to derive the AES-256 storage key. Preserve it with the data. |
| `trash_retention_days` | Number | `7` | Retention period in days for files in the trash before automated permanent deletion. Set to `-1` to disable automatic deletion (keep deleted files forever). |

---

## Storage & Hashed Layout

If `"hash_files"` is enabled, the server hides physical file structures from the host OS:
1. Files are uploaded and named on disk according to their SHA-256 hash (stored in `storage_root/data/SHA256_HASH`).
2. Identical files uploaded by different users are **deduplicated** automatically to save disk space.
3. The virtual directory hierarchy and metadata (original names, file paths, types) are mapped in the SQLite database's `file_index` table.
4. If an `"encryption_key"` is supplied, files are stored on disk as encrypted AES streams and decrypted on-the-fly during downloads.

---

## API Endpoints Reference

All API calls must contain standard HTTP headers. Unless noted otherwise, endpoints returning JSON default to the `application/json` Content-Type.

Endpoints marked with `[Auth]` require a valid bearer token header:
`Authorization: Bearer <access_token>`

### 1. Authentication Endpoints

#### Register User
- **URL:** `/api/register`
- **Method:** `POST`
- **Request Body (JSON):**
  ```json
  {
    "username": "user123",
    "password": "strongpassword"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "ok": true,
    "message": "User registered successfully"
  }
  ```

#### Login User
- **URL:** `/api/login`
- **Method:** `POST`
- **Request Body (JSON):**
  ```json
  {
    "username": "user123",
    "password": "strongpassword"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "7ef9b0...",
    "username": "user123"
  }
  ```

#### Refresh Access Token
- **URL:** `/api/refresh`
- **Method:** `POST`
- **Request Body (JSON):**
  ```json
  {
    "refreshToken": "7ef9b0..."
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "accessToken": "eyJhbGciOi..."
  }
  ```

#### Logout User
- **URL:** `/api/logout`
- **Method:** `POST`
- **Headers:** `[Auth]`
- **Request Body (JSON):**
  ```json
  {
    "refreshToken": "7ef9b0..."
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "ok": true
  }
  ```

---

### 2. File and Directory Endpoints

#### List Directory (Dual JSON / Protobuf)
- **URL:** `/api/dir`
- **Method:** `GET`
- **Headers:** `[Auth]`
- **Query Parameters:**
  - `scope` (Required): `private` or `shared`
  - `path` (Optional): Relative directory path (e.g. `"documents/work"`). If empty, returns root.
  - `type` (Optional): Filter items by category (`all`, `image`, `video`, `audio`, `document`).
  - `q` (Optional): Query string for recursive search.
  - `sort` (Optional): Sorting parameter (`name`, `size`, `date`, `type`).
  - `order` (Optional): Sorting order (`asc` or `desc`).
- **Dual Serialization Protocol:**
  - **Protobuf Format:** Send `Accept: application/x-protobuf` header. The server will serialize the directory tree directly into a binary stream using the `DirResponse` message structure.
  - **JSON Fallback:** If `Accept` does not request protobuf, the server returns:
    ```json
    {
      "entries": [
        {
          "name": "project_report.pdf",
          "path": "documents/work/project_report.pdf",
          "is_dir": false,
          "size": 1420580,
          "modified_at": 1782294103000,
          "type": "document",
          "mime_type": "application/pdf",
          "thumbnail_url": "/api/thumb?scope=private&path=documents/work/project_report.pdf&s=256"
        }
      ]
    }
    ```

#### Upload File
- **URL:** `/api/files`
- **Method:** `POST`
- **Headers:** `[Auth]`, `Content-Type: application/octet-stream`
- **Query Parameters:**
  - `scope`: `private`
  - `path`: Upload target relative file path.
  - `offset` (Optional): Chunk start offset in bytes (for chunked uploading).
  - `total` (Optional): Total file size in bytes.
  - `is_last` (Optional): Set `true` on the final chunk.
- **Response (200 OK):**
  ```json
  {
    "ok": true,
    "path": "documents/work/project_report.pdf"
  }
  ```

#### Check Upload Status
- **URL:** `/api/files/upload-status`
- **Method:** `GET`
- **Headers:** `[Auth]`
- **Query Parameters:**
  - `scope`: `private`
  - `path`: Target file path.
- **Response (200 OK):**
  ```json
  {
    "bytes_received": 1024000
  }
  ```

#### Download File
- **URL:** `/api/files`
- **Method:** `GET`
- **Headers:** `[Auth]`
- **Query Parameters:**
  - `scope`: `private` or `shared`
  - `path`: File path to download.
- **Response (200 OK):** Binary file octet-stream payload.

#### Create Folder
- **URL:** `/api/folders`
- **Method:** `POST`
- **Headers:** `[Auth]`
- **Query Parameters:**
  - `scope`: `private`
  - `path`: Folder path to create.
- **Response (200 OK):**
  ```json
  {
    "ok": true
  }
  ```

#### Get Media Thumbnail
- **URL:** `/api/thumb`
- **Method:** `GET`
- **Headers:** `[Auth]`
- **Query Parameters:**
  - `scope`: `private` or `shared`
  - `path`: Media file path.
  - `s` (Optional): Dimensions bounding box (default `256`).
- **Response (200 OK):** Binary JPEG/PNG image data of the extracted thumbnail.

---

### 3. Trash Operations (Dual JSON / Protobuf)

#### List Trash Entries
- **URL:** `/api/trash`
- **Method:** `GET`
- **Headers:** `[Auth]`
- **Query Parameters:**
  - `scope` (Optional): `private` (default)
  - `q` (Optional): Search query to filter items.
- **Dual Serialization Protocol:**
  - **Protobuf Format:** Send `Accept: application/x-protobuf` header to parse a binary representation using `DirResponse` message structure (includes file `id`).
  - **JSON Fallback:** Returns:
    ```json
    {
      "entries": [
        {
          "id": 42,
          "name": "draft.txt",
          "path": "notes/draft.txt",
          "is_dir": false,
          "size": 521,
          "modified_at": 1782312015000,
          "type": "file",
          "mime_type": "text/plain"
        }
      ]
    }
    ```

#### Restore Items from Trash
- **URL:** `/api/trash/restore`
- **Method:** `POST`
- **Headers:** `[Auth]`
- **Request Body (JSON):**
  ```json
  {
    "ids": [42]
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "ok": true
  }
  ```

#### Empty/Delete Items in Trash
- **URL:** `/api/trash`
- **Method:** `DELETE`
- **Headers:** `[Auth]`
- **Request Body (JSON):**
  ```json
  {
    "ids": [42]
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "ok": true
  }
  ```

---

### 4. Shared Links

#### Create Shared Link
- **URL:** `/api/share`
- **Method:** `POST`
- **Headers:** `[Auth]`
- **Request Body (JSON):**
  ```json
  {
    "scope": "private",
    "path": "documents/work/project_report.pdf"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "url": "s/xyz789token"
  }
  ```

#### Public Share Access
- **URL:** `/s/{token}`
- **Method:** `GET`
- **Response (200 OK):** Resolves the public mapping to download the shared asset directly without authentication.

---

## Protobuf Schema Compilation

The directory and trash structures are defined in [dir_entry.proto](file:///../proto/dir_entry.proto):

```protobuf
syntax = "proto3";

package server.proto;

message DirEntry {
  string name = 1;
  string path = 2;
  bool is_dir = 3;
  uint64 size = 4;
  int64 modified_at = 5;
  string type = 6;
  string mime_type = 7;
  string thumbnail_url = 8;
  int64 id = 9;
}

message DirResponse {
  repeated DirEntry entries = 1;
}
```

If you modify this schema, run the generation script from the project root:
```bash
./scripts/generate_proto.sh
```
This updates both C++ headers inside the server build target and Dart serialization files inside the Flutter app.

## Local configuration overrides

The server loads its selected base config (`config/config.json` by default),
then automatically applies **`config.local.json` from the same directory**.
If it does not exist yet, you can create it from `config/config.local.example.json`; include only the
values that should differ on your machine, for example:

```json
{
  "port": 9090,
  "log_level": "DEBUG",
  "access_log_enabled": false
}
```

All omitted fields come from the base config, including parameters added by a
new server release. `{}` changes nothing. Values such as `false`, `0`, and
`""` are explicit overrides; `null` is not supported. Malformed/unreadable local
files stop startup instead of silently reverting the configuration.

Start the server normally, or supply the **base file** as its first argument:

```bash
./build/crowleys_cloud_server config/config.json
```

An explicitly supplied `config.local.json` also includes the adjacent
`config.json`. For other custom base filenames, the override is still named
`config.local.json` in the same directory. Relative storage/log/database paths
keep their usual base-config application directory, regardless of the shell's
working directory.

Precedence: built-in defaults → base JSON → local JSON → supported environment
variables (`CROWLEYS_JWT_SECRET`, `CROWLEYS_ENCRYPTION_KEY`). Local configuration
does not bypass secret validation or rotate keys. Preserve the existing storage
key when configuring a populated server.

The local file is ignored by Git and excluded from CMake installation, release
archives and Docker build context. Updating files in an existing installation
preserves it; if installing into a new directory, copy it along with the data.
Back it up, and do not copy the entire base config into it, or new defaults for
those copied fields will remain overridden.

## First startup and persistent secrets

On a fresh installation, start the server normally. Missing or shipped example
secrets are replaced with independent random 32-byte values (64 hexadecimal
characters), saved to `config.local.json` alongside the selected base config.
Existing local fields are preserved. Subsequent launches, `git pull` and release
updates reuse these values; they do not rewrite the local file.

You can instead supply `jwt_secret` and `encryption_key` in local configuration,
or `CROWLEYS_JWT_SECRET` / `CROWLEYS_ENCRYPTION_KEY` in the environment. Environment
values take precedence and are not copied into the local file. Each secret must
have at least 32 characters; the encryption key is required with `hash_files=true`.
Docker Compose continues to require the explicitly configured environment secrets.

Automatic initialization refuses to proceed if a database or nonempty storage
already exists. Restore the original keys, or, for a disposable test installation,
stop the server and move the old database and storage out of the configured paths
before starting fresh. Never replace a populated storage key without migrating
the encrypted data. Back up `config.local.json` with the database and storage.

Initialization writes a temporary file before replacing the local config and
uses a `config.local.json.init-lock` directory to exclude concurrent writers.
On Linux/macOS the generated file has mode `0600`; on Windows it inherits the
user folder's permissions. If a crash leaves the lock behind, stop all server
processes before removing that directory and retrying. Failure to save secrets
stops startup; the server does not use temporary in-memory keys.

For Windows/macOS, unpack the complete release into a permanent writable folder.
Stop the server before extracting an update into the same folder. Keep the local
config and data if moving to another folder. See the platform guides in
`server/scripts/windows/README.md` and `server/scripts/macos/README.md`.

Access and background-sync tokens are now bound to the user's password hash.
Upgrading invalidates previously issued access/sync tokens; sign in again.
Password changes and account deletion invalidate those tokens immediately.

## Administration

See [the administration guide](../docs/administration.md) for account approval,
roles and quotas, live configuration, session revocation and recoverable encryption
key rotation. New installations default to registration approval after the first
administrator account; existing accounts stay active during the upgrade.
