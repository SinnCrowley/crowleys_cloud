# Server administration

The first account on a fresh installation is an active administrator. On upgrade,
existing accounts stay active; a one-time migration promotes the earliest surviving
account if the database has no administrator. The last usable administrator cannot
be blocked, demoted, deleted, or placed into password recovery.

The web client exposes **Administration** at the bottom of its navigation menu.
The server checks current roles independently of the menu and of roles embedded
in old tokens. Synchronization tokens never grant administrative access.

## Registration, accounts and quotas

`registration_mode` is `approval` by default. It also accepts `open` and `closed`.
Pending registrations receive HTTP 202 without session tokens. Administrators
approve or reject them in Registration requests. Rejection releases the username.

Blocking revokes all account sessions, including synchronization tokens, and suspends
public links until unblocking. Password recovery codes are issued only through the
administration API, shown once, stored as hashes, valid for 10 minutes, and invalidated
after five failed attempts. Public recovery requests neither generate nor log codes.

`default_quota_bytes` defaults to 0 (unlimited). A user's `quota_bytes` is null to
inherit the default, 0 for unlimited, or a positive byte count. Quotas count logical
original file sizes, including shared files and trash, excluding thumbnails and
encryption overhead. Lowering a quota does not remove files; only increases in
usage are rejected. Resumable upload reservations last 24 hours and are rechecked
on each resumed chunk. Parallel writes reserve capacity before publication.

Deleting a user removes personal data, trash, sessions and public links. Shared
personal files are copied/verified into a uniquely named `Transferred-...` directory
owned by the deleting administrator. Legacy shared-storage entries keep their paths
and change uploader. The recipient needs enough quota. A failed deletion keeps a
journal and resumes on server startup or by retrying deletion in the UI. Do not
remove its journal or source files manually.

## Configuration

The API returns effective and saved values, source, application mode and a revision.
Updates require the revision from the last read; stale updates return 409.
Changes are saved to the selected base file's sibling `config.local.json` using a
private temporary file, durable write and atomic replacement. The base file remains
unchanged. Infrastructure changes require an operator-managed restart. Changes to
populated storage, database paths or storage format require a manual migration.
Path edits must be absolute. Live upload limits are checked by the application,
including complete chunked-file sizes; transport request buffering spills to disk
above 1 MiB.

Environment secrets (`CROWLEYS_JWT_SECRET`, `CROWLEYS_ENCRYPTION_KEY`) retain priority
and cannot be changed by the administration API. Secret fields are never returned.
Changing the signing secret revokes all access, refresh and synchronization sessions,
including the initiating session. Public share links and files are unaffected.

## Encryption rotation and recovery

Use the encryption-key operation; do not replace an existing storage key directly
in configuration. During rotation, new file operations return HTTP 503 with
`code: maintenance`, `Retry-After: 5`, and `X-Crowley-Maintenance: true`. Existing
streams are drained before replacing objects. Login and administrative status remain
available. Background thumbnails and trash cleanup stop accessing storage.

Every unique encrypted object is processed, including objects referenced by trash.
Plaintext flows through memory only. Each new ciphertext is decrypted for verification
against its SHA-256 name and recorded original size before replacement. Durable
SQLite stages and old/new ciphertext hashes distinguish crashes before and after
replacement. Derived thumbnails are invalidated for regeneration.

The private `encryption-rotation.keys.json` alongside the configuration temporarily
holds both keys. Keep it with the database, storage and configuration if moving or
restoring a server during an unfinished rotation. It is removed only after all objects
are checked and the new configuration is durable. Disk space is needed for one extra
encrypted object at a time. On failure, repair the storage problem and use Continue;
startup also resumes unfinished work. Cancellation after starting is unsupported.

The implementation supports a single server process owning a storage/database pair.
File mutations are serialized; network downloads can run concurrently.

## API groups

- `GET /api/account`: current account and quota usage.
- `GET /api/admin/users`, `GET /api/admin/applications`.
- `PATCH /api/admin/users/{id}`: role, state and quota.
- `POST /api/admin/users/{id}/{approve|reject|reset-password|revoke-sessions}`.
- `DELETE /api/admin/users/{id}`: transfer shared files and delete account.
- `GET/PATCH /api/admin/config`: revisioned configuration.
- `POST /api/admin/signing-secret`: `{revision, secret}`.
- `GET /api/admin/maintenance`: progress, operation phase and error code.
- `POST /api/admin/encryption-key`: `{revision, secret}`.
- `POST /api/admin/encryption-key/resume`: retry a paused operation.

Administrative mutations are recorded in `admin_audit` without passwords, recovery
codes or keys. Responses containing settings, user lists, recovery codes or operation
status disable caching.
