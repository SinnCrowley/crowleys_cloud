# Crowley's Cloud Server

A high-performance, low-latency, and resource-efficient cloud storage backend built with the C++ **Drogon** web framework, **SQLite3**, and **Protocol Buffers**.

---

## Technical Stack & Architecture

- **Web Framework:** [Drogon](https://github.com/drogonframework/drogon) (C++20, asynchronous event-driven network engine)
- **Database Engine:** Embedded SQLite3 (handles users, file indexing, trash, and shares)
- **Serialization:** Protocol Buffers over HTTP (`application/x-protobuf`) for directories/trash listings, falling back to JSON
- **Cryptographic Operations:** OpenSSL (SHA-256 file hashing, AES-256-CBC local file encryption)
- **Compression:** ZLIB (CRC32 calculations & raw zip archives stream compiling)

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

### On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake libssl-dev libsqlite3-dev zlib1g-dev protobuf-compiler libprotobuf-dev pkg-config libjsoncpp-dev uuid-dev ffmpeg
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
3. **Run the server:**
   The server expects a configuration file path as an argument. By default, it will search for `config/config.json`.
   ```bash
   ./build/crowleys_cloud_server
   ```

---

## Configuration (`config.json`)

Configuration settings are loaded from `server/config/config.json`. Below is a breakdown of all parameters:

| Parameter Key | Type | Example Value | Description |
| :--- | :---: | :--- | :--- |
| `host` | String | `"0.0.0.0"` | IP address the HTTP server binds to (`0.0.0.0` listens on all interfaces). |
| `port` | Number | `8080` | TCP port for incoming HTTP traffic. |
| `storage_root` | String | `"./storage"` | Local directory where physical user files are saved. |
| `jwt_secret` | String | `"your-jwt-secret"` | Signature secret key used to issue and verify JWT access tokens. |
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
| `encryption_key` | String | `"aes-key"` | 256-bit AES key used to encrypt raw files inside `storage/` on disk. |

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
