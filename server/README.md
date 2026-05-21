# Crowleys Cloud Server (v1)

## Build

```bash
cd server
cmake -S . -B build
cmake --build build -j
```

## Run

```bash
cd server
./build/crowleys_cloud_server
```

The server loads config from `server/config/config.json`.

## API summary

- `POST /api/register`
- `POST /api/login`
- `POST /api/refresh`
- `POST /api/logout`
- `POST /api/account/password` (auth required)
- `DELETE /api/account` (auth required)
- `GET /api/dir?scope=private|shared&path=...` (auth required)
- `GET /api/files?scope=private|shared&path=...` (auth required)
- `POST /api/files?scope=private|shared&path=...` (auth required)
- `DELETE /api/files?scope=private|shared&path=...` (auth required)
- `POST /api/share` (auth required)
- `GET /s/{token}` (public, read/download only)

## Notes

- First registered user is assigned `owner` role.
- Shared storage: everyone can read, only owner can write/delete.
- Access token TTL is 1 day, refresh token TTL is 90 days.
