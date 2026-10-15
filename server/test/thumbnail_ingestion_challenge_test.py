#!/usr/bin/env python3
"""
Empirical Challenge Test Suite: Backend Video Thumbnail Ingestion
Milestone 1 Verification

Tests:
1. Client thumbnail upload via multipart, chunked (X-Thumbnail), and raw upload.
2. Immediate GET /api/thumb cache hit returning 200 image/webp with exact bytes.
3. FFmpeg process bypass: zero FFmpeg invocations when client thumbnail is provided.
4. FFmpeg fallback: FFmpeg queue is invoked when thumbnail is omitted or corrupt.
5. Non-WebP format rejection and graceful fallback.
6. ETag 304 Not Modified caching.
7. Filename encoding & special characters.
8. Shared scope thumbnail ingestion and cross-user retrieval.
9. Concurrency stress: parallel uploads and immediate parallel thumbnail retrievals.
10. Execution across both hash_files=True and hash_files=False storage modes.
"""

import base64
import concurrent.futures
import http.client
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import sqlite3
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlencode

SERVER_BIN = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else (Path(__file__).resolve().parent.parent / 'build' / 'crowleys_cloud_server')
if not SERVER_BIN.is_file():
    print(f"Error: Server binary not found at {SERVER_BIN}", file=sys.stderr)
    sys.exit(1)

# Generate a valid MP4 test video using ffmpeg
def generate_sample_mp4(dest_path: Path, duration: int = 3):
    cmd = [
        'ffmpeg', '-y', '-f', 'lavfi', '-i', f'testsrc=duration={duration}:size=64x64:rate=1',
        '-c:v', 'libx264', '-pix_fmt', 'yuv420p', str(dest_path)
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Generate a valid 64x64 WebP thumbnail using ffmpeg
def generate_sample_webp(dest_path: Path) -> bytes:
    cmd = [
        'ffmpeg', '-y', '-f', 'lavfi', '-i', 'testsrc=duration=1:size=64x64:rate=1',
        '-vframes', '1', '-c:v', 'libwebp', '-quality', '85', str(dest_path)
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return dest_path.read_bytes()


class ServerHarness:
    def __init__(self, root: Path, hash_files: bool):
        self.root = root
        self.hash_files = hash_files
        self.storage_dir = root / 'storage'
        self.db_path = root / 'db.sqlite'
        self.upload_dir = root / 'uploads'
        self.public_dir = root / 'public'
        self.log_dir = root / 'logs'
        self.ffmpeg_log = root / 'ffmpeg_tracker.log'

        # Create ffmpeg wrapper script
        self.ffmpeg_wrapper = root / 'ffmpeg_tracker.sh'
        self.ffmpeg_wrapper.write_text(f"""#!/usr/bin/env bash
echo "$@" >> {self.ffmpeg_log.resolve()}
exec /usr/bin/ffmpeg "$@"
""")
        self.ffmpeg_wrapper.chmod(0o755)

        # Find free port
        with socket.socket() as s:
            s.bind(('127.0.0.1', 0))
            self.port = s.getsockname()[1]

        self.config = {
            'host': '127.0.0.1',
            'port': self.port,
            'storage_root': str(self.storage_dir),
            'db_path': str(self.db_path),
            'temp_upload_dir': str(self.upload_dir),
            'public_dir': str(self.public_dir),
            'log_dir': str(self.log_dir),
            'hash_files': hash_files,
            'jwt_secret': secrets.token_hex(32),
            'encryption_key': secrets.token_hex(32),
            'rate_limit_per_minute': 1000,
            'trash_retention_days': 7,
            'registration_mode': 'open',
            'video_thumbs_enabled': True,
            'ffmpeg_binary': str(self.ffmpeg_wrapper)
        }
        self.config_path = root / 'config.json'
        self.config_path.write_text(json.dumps(self.config))

        self.server_log = root / 'server.log'
        self.process = None

    def start(self):
        log_file = self.server_log.open('w')
        env = {k: v for k, v in os.environ.items() if k not in ('CROWLEYS_JWT_SECRET', 'CROWLEYS_ENCRYPTION_KEY')}
        self.process = subprocess.Popen(
            [str(SERVER_BIN), str(self.config_path)],
            stdout=log_file,
            stderr=log_file,
            env=env
        )
        # Wait for startup
        for _ in range(100):
            if self.process.poll() is not None:
                raise RuntimeError(f"Server exited prematurely:\n{self.server_log.read_text()}")
            try:
                conn = http.client.HTTPConnection('127.0.0.1', self.port, timeout=1)
                conn.request('GET', '/')
                conn.getresponse()
                conn.close()
                return
            except OSError:
                time.sleep(0.05)
        raise TimeoutError("Server failed to respond within 5s")

    def stop(self):
        if self.process and self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.process.kill()

    def get_ffmpeg_call_count(self) -> int:
        if not self.ffmpeg_log.exists():
            return 0
        lines = [l.strip() for l in self.ffmpeg_log.read_text().splitlines() if l.strip()]
        return len(lines)

    def get_ffmpeg_log(self) -> str:
        if not self.ffmpeg_log.exists():
            return ""
        return self.ffmpeg_log.read_text()

    def request(self, path, data=None, token=None, method=None, extra_headers=None):
        headers = {}
        if isinstance(data, dict):
            data = json.dumps(data).encode()
            headers['Content-Type'] = 'application/json'
        elif isinstance(data, (bytes, bytearray)):
            headers['Content-Type'] = 'application/octet-stream'
        if token:
            headers['Authorization'] = f'Bearer {token}'
        if extra_headers:
            headers.update(extra_headers)

        conn = http.client.HTTPConnection('127.0.0.1', self.port, timeout=10)
        try:
            m = method or ('POST' if data is not None else 'GET')
            conn.request(m, path, data, headers)
            res = conn.getresponse()
            res_headers = dict(res.getheaders())
            return res.status, res.read(), res_headers
        finally:
            conn.close()

    def register_user(self, username, password):
        status, body, _ = self.request('/api/register', {'username': username, 'password': password})
        assert status == 200, f"Register failed: {status} {body}"
        return json.loads(body)['access_token']


def run_tests_for_mode(hash_files: bool):
    mode_name = f"hash_files={hash_files}"
    print(f"\n=======================================================")
    print(f" [RUN] Running Challenge Tests under {mode_name}")
    print(f"=======================================================")

    tmp_dir = tempfile.mkdtemp(prefix=f'challenge-test-{hash_files}-')
    root = Path(tmp_dir)
    harness = ServerHarness(root, hash_files=hash_files)
    harness.start()

    try:
            token = harness.register_user('tester', 'secure_pass_123')
            sample_mp4 = root / 'sample.mp4'
            generate_sample_mp4(sample_mp4)
            sample_mp4_bytes = sample_mp4.read_bytes()

            sample_webp = root / 'sample.webp'
            valid_webp_bytes = generate_sample_webp(sample_webp)
            valid_webp_b64 = base64.b64encode(valid_webp_bytes).decode('ascii')

            # Helper for multipart upload
            def upload_multipart(path, file_data, thumb_data=None, thumb_field="thumbnail"):
                boundary = '----ChallengerBoundary' + secrets.token_hex(16)
                parts = []
                parts.append(
                    f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{os.path.basename(path)}"\r\nContent-Type: video/mp4\r\n\r\n'.encode()
                    + file_data + b'\r\n'
                )
                if thumb_data is not None:
                    parts.append(
                        f'--{boundary}\r\nContent-Disposition: form-data; name="{thumb_field}"; filename="thumb.webp"\r\nContent-Type: image/webp\r\n\r\n'.encode()
                        + thumb_data + b'\r\n'
                    )
                parts.append(f'--{boundary}--\r\n'.encode())
                body = b''.join(parts)
                url = '/api/files?' + urlencode({'scope': 'private', 'path': path})
                return harness.request(url, body, token=token, extra_headers={'Content-Type': f'multipart/form-data; boundary={boundary}'})

            # Helper for chunked upload
            def upload_chunked(path, file_data, thumb_b64=None, chunk_size=1024):
                total = len(file_data)
                offset = 0
                status = 0
                while offset < total:
                    chunk = file_data[offset:offset + chunk_size]
                    is_last = (offset + len(chunk) == total)
                    params = {
                        'scope': 'private',
                        'path': path,
                        'offset': offset,
                        'total': total,
                        'is_last': 'true' if is_last else 'false'
                    }
                    extra_headers = {}
                    if is_last and thumb_b64 is not None:
                        extra_headers['X-Thumbnail'] = thumb_b64
                    url = '/api/files?' + urlencode(params)
                    status, body, _ = harness.request(url, chunk, token=token, extra_headers=extra_headers)
                    if status >= 300:
                        return status, body
                    offset += len(chunk)
                return status, body

            # -------------------------------------------------------------
            # TEST 1: Multipart single upload with client thumbnail & bypass
            # -------------------------------------------------------------
            print("1. Testing multipart upload with WebP thumbnail (verifying FFmpeg bypass)...")
            initial_ffmpeg = harness.get_ffmpeg_call_count()
            status, resp_body, _ = upload_multipart('clip1.mp4', sample_mp4_bytes, valid_webp_bytes)
            assert status == 201, f"Expected 201 Created, got {status}: {resp_body}"

            # Verify FFmpeg was NOT invoked
            ffmpeg_after_upload = harness.get_ffmpeg_call_count()
            assert ffmpeg_after_upload == initial_ffmpeg, f"FFmpeg was spawned! Count changed from {initial_ffmpeg} to {ffmpeg_after_upload}"

            # Verify immediate GET /api/thumb returns 200 image/webp
            status, thumb_body, thumb_headers = harness.request(
                '/api/thumb?' + urlencode({'scope': 'private', 'path': 'clip1.mp4', 's': 256}),
                token=token
            )
            assert status == 200, f"Expected 200 OK from /api/thumb, got {status}"
            assert thumb_headers.get('content-type') == 'image/webp', f"Bad Content-Type: {thumb_headers.get('content-type')}"
            assert thumb_body == valid_webp_bytes, "Thumbnail body does not match uploaded WebP bytes"
            assert 'etag' in thumb_headers, "Missing ETag in thumbnail response"
            etag = thumb_headers['etag']

            # Test ETag conditional request
            status, _, _ = harness.request(
                '/api/thumb?' + urlencode({'scope': 'private', 'path': 'clip1.mp4', 's': 256}),
                token=token,
                extra_headers={'If-None-Match': etag}
            )
            assert status == 304, f"Expected 304 Not Modified, got {status}"

            # Verify FFmpeg was STILL not invoked
            assert harness.get_ffmpeg_call_count() == initial_ffmpeg, "FFmpeg was spawned during /api/thumb request!"

            # Verify SQLite file_index record
            conn = sqlite3.connect(harness.db_path)
            c = conn.cursor()
            c.execute("SELECT thumbnail_path, thumbnail_updated_at, blurhash FROM file_index WHERE rel_path = 'clip1.mp4'")
            row = c.fetchone()
            assert row is not None, "clip1.mp4 not found in file_index"
            assert row[0] == 'client', f"Expected thumbnail_path='client', got {row[0]}"
            assert row[1] > 0, f"Expected thumbnail_updated_at > 0, got {row[1]}"
            assert len(row[2]) > 0, f"Expected non-empty blurhash, got '{row[2]}'"
            print(f"   -> blurhash: {row[2]}")
            conn.close()
            print("   -> PASS: Multipart client thumbnail stored, bypassed FFmpeg, retrieved with 200, ETag 304 verified.")

            # -------------------------------------------------------------
            # TEST 2: Chunked upload with X-Thumbnail header & bypass
            # -------------------------------------------------------------
            print("2. Testing chunked upload with X-Thumbnail header (verifying FFmpeg bypass)...")
            initial_ffmpeg = harness.get_ffmpeg_call_count()
            status, resp_body = upload_chunked('chunked_clip.mp4', sample_mp4_bytes, valid_webp_b64, chunk_size=512)
            assert status == 201, f"Expected 201 Created for chunked upload, got {status}: {resp_body}"

            # Verify FFmpeg was NOT invoked
            assert harness.get_ffmpeg_call_count() == initial_ffmpeg, "FFmpeg was spawned during chunked upload!"

            # Verify immediate GET /api/thumb
            status, thumb_body, thumb_headers = harness.request(
                '/api/thumb?' + urlencode({'scope': 'private', 'path': 'chunked_clip.mp4', 's': 256}),
                token=token
            )
            assert status == 200, f"Expected 200 OK from /api/thumb for chunked clip, got {status}"
            assert thumb_headers.get('content-type') == 'image/webp'
            assert thumb_body == valid_webp_bytes
            assert harness.get_ffmpeg_call_count() == initial_ffmpeg, "FFmpeg was spawned during chunked /api/thumb!"
            print("   -> PASS: Chunked upload ingested thumbnail, bypassed FFmpeg, served immediately.")

            # -------------------------------------------------------------
            # TEST 3: Single raw upload with X-Thumbnail header & bypass
            # -------------------------------------------------------------
            print("3. Testing single raw upload with X-Thumbnail header (verifying FFmpeg bypass)...")
            initial_ffmpeg = harness.get_ffmpeg_call_count()
            url = '/api/files?' + urlencode({'scope': 'private', 'path': 'raw_clip.mp4'})
            status, resp_body, _ = harness.request(
                url,
                sample_mp4_bytes,
                token=token,
                extra_headers={'X-Thumbnail': valid_webp_b64}
            )
            assert status == 201, f"Expected 201 for raw upload, got {status}: {resp_body}"
            assert harness.get_ffmpeg_call_count() == initial_ffmpeg, "FFmpeg was spawned during raw upload!"

            status, thumb_body, _ = harness.request(
                '/api/thumb?' + urlencode({'scope': 'private', 'path': 'raw_clip.mp4', 's': 256}),
                token=token
            )
            assert status == 200, f"Expected 200 for raw clip thumb, got {status}"
            assert thumb_body == valid_webp_bytes
            print("   -> PASS: Raw upload ingested thumbnail, bypassed FFmpeg, served immediately.")

            # -------------------------------------------------------------
            # TEST 4: Fallback to FFmpeg queue when NO thumbnail is provided
            # -------------------------------------------------------------
            print("4. Testing fallback when NO thumbnail provided (verifying FFmpeg invocation)...")
            initial_ffmpeg = harness.get_ffmpeg_call_count()
            fallback_mp4 = root / 'fallback_sample.mp4'
            generate_sample_mp4(fallback_mp4, duration=4)
            fallback_mp4_bytes = fallback_mp4.read_bytes()
            status, resp_body, _ = upload_multipart('fallback_clip.mp4', fallback_mp4_bytes, thumb_data=None)
            assert status == 201, f"Expected 201 for fallback clip, got {status}"

            # Wait for ThumbnailQueue background worker to process task
            ffmpeg_triggered = False
            for _ in range(50):
                if harness.get_ffmpeg_call_count() > initial_ffmpeg:
                    ffmpeg_triggered = True
                    break
                time.sleep(0.1)
            assert ffmpeg_triggered, f"FFmpeg was NOT triggered on fallback! Count stayed at {initial_ffmpeg}. Log: {harness.get_ffmpeg_log()}"

            # Verify that server-generated thumbnail is now served
            thumb_available = False
            for attempt in range(50):
                status, thumb_body, thumb_h = harness.request(
                    '/api/thumb?' + urlencode({'scope': 'private', 'path': 'fallback_clip.mp4', 's': 256}),
                    token=token
                )
                print(f"   [poll {attempt}] status={status}, len={len(thumb_body)}, content-type={thumb_h.get('content-type')}")
                if status == 200 and len(thumb_body) > 0:
                    thumb_available = True
                    break
                time.sleep(0.1)
            assert thumb_available, f"Thumbnail not available after FFmpeg fallback, status={status}, len={len(thumb_body)}"
            print("   -> PASS: Upload without thumbnail correctly triggered FFmpeg fallback and served generated thumbnail.")

            # -------------------------------------------------------------
            # TEST 5: Fallback when CORRUPT thumbnail is provided
            # -------------------------------------------------------------
            print("5. Testing fallback when CORRUPT thumbnail provided...")
            initial_ffmpeg = harness.get_ffmpeg_call_count()
            corrupt_bytes = b'RIFF\x20\x00\x00\x00CORRUPT_NOT_A_WEBP_PAYLOAD_12345'
            corrupt_sample_mp4 = root / 'corrupt_sample.mp4'
            generate_sample_mp4(corrupt_sample_mp4, duration=5)
            corrupt_sample_mp4_bytes = corrupt_sample_mp4.read_bytes()
            status, resp_body, _ = upload_multipart('corrupt_clip.mp4', corrupt_sample_mp4_bytes, corrupt_bytes)
            assert status == 201, f"Expected 201 (graceful handling of corrupt thumb), got {status}"

            # Wait for ThumbnailQueue to invoke FFmpeg as fallback
            ffmpeg_triggered = False
            for _ in range(50):
                if harness.get_ffmpeg_call_count() > initial_ffmpeg:
                    ffmpeg_triggered = True
                    break
                time.sleep(0.1)
            assert ffmpeg_triggered, f"FFmpeg was NOT triggered on corrupt fallback! Count stayed at {initial_ffmpeg}"
            print("   -> PASS: Corrupt thumbnail cleanly rejected and triggered FFmpeg fallback.")

            # -------------------------------------------------------------
            # TEST 6: Non-WebP format (JPEG) rejected and falls back
            # -------------------------------------------------------------
            print("6. Testing non-WebP thumbnail payload (JPEG bytes) rejection...")
            initial_ffmpeg = harness.get_ffmpeg_call_count()
            fake_jpeg = b'\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00' + b'\x00' * 50
            jpeg_sample_mp4 = root / 'jpeg_sample.mp4'
            generate_sample_mp4(jpeg_sample_mp4, duration=6)
            jpeg_sample_mp4_bytes = jpeg_sample_mp4.read_bytes()
            status, _, _ = upload_multipart('jpeg_thumb_clip.mp4', jpeg_sample_mp4_bytes, fake_jpeg)
            assert status == 201

            ffmpeg_triggered = False
            for _ in range(50):
                if harness.get_ffmpeg_call_count() > initial_ffmpeg:
                    ffmpeg_triggered = True
                    break
                time.sleep(0.1)
            assert ffmpeg_triggered, "FFmpeg was NOT triggered when client sent non-WebP JPEG thumbnail!"
            print("   -> PASS: Non-WebP payload correctly rejected and routed to fallback.")

            # -------------------------------------------------------------
            # TEST 7: Filename with unicode and spaces
            # -------------------------------------------------------------
            print("7. Testing unicode and spaces in filename...")
            initial_ffmpeg = harness.get_ffmpeg_call_count()
            unicode_name = 'моё видео 2026.mp4'
            status, _, _ = upload_multipart(unicode_name, sample_mp4_bytes, valid_webp_bytes)
            assert status == 201
            assert harness.get_ffmpeg_call_count() == initial_ffmpeg, "FFmpeg spawned on unicode upload!"

            status, thumb_body, _ = harness.request(
                '/api/thumb?' + urlencode({'scope': 'private', 'path': unicode_name, 's': 256}),
                token=token
            )
            assert status == 200, f"Expected 200 for unicode thumbnail, got {status}"
            assert thumb_body == valid_webp_bytes
            print("   -> PASS: Unicode filename correctly indexed, cached, and retrieved.")

            # -------------------------------------------------------------
            # TEST 8: Shared scope upload and retrieval
            # -------------------------------------------------------------
            print("8. Testing shared scope thumbnail ingestion and cross-user access...")
            user2_token = harness.register_user('user2', 'user2_pass_456')

            # User 1 creates and shares a folder
            status, body, _ = harness.request('/api/folders?' + urlencode({'scope': 'private', 'path': 'SharedFolder'}), method='POST', token=token)
            assert status < 300, f"createFolder failed: {status} {body}"
            status, share_resp, _ = harness.request('/api/files/share?' + urlencode({'path': 'SharedFolder', 'shared': '1'}), method='POST', token=token)
            assert status < 300, f"Failed to share folder: {share_resp}"

            # User 1 uploads video with client thumbnail into SharedFolder
            initial_ffmpeg = harness.get_ffmpeg_call_count()
            status, _, _ = upload_multipart('SharedFolder/shared_video.mp4', sample_mp4_bytes, valid_webp_bytes)
            assert status == 201
            assert harness.get_ffmpeg_call_count() == initial_ffmpeg, "FFmpeg spawned on shared folder upload!"

            # User 2 accesses thumbnail via scope=shared
            status, thumb_body, _ = harness.request(
                '/api/thumb?' + urlencode({'scope': 'shared', 'path': 'SharedFolder/shared_video.mp4', 's': 256}),
                token=user2_token
            )
            assert status == 200, f"Expected 200 for user2 accessing shared thumbnail, got {status}"
            assert thumb_body == valid_webp_bytes
            assert harness.get_ffmpeg_call_count() == initial_ffmpeg, "FFmpeg spawned on shared thumbnail query!"
            print("   -> PASS: Shared scope thumbnail ingestion and cross-user query passed with zero FFmpeg calls.")

            # -------------------------------------------------------------
            # TEST 9: Concurrency Stress Test (10 parallel uploads & queries)
            # -------------------------------------------------------------
            print("9. Running concurrency stress test (10 parallel uploads & queries)...")
            initial_ffmpeg = harness.get_ffmpeg_call_count()

            def stress_worker(i):
                fname = f'stress_video_{i}.mp4'
                st, _, _ = upload_multipart(fname, sample_mp4_bytes, valid_webp_bytes)
                if st != 201:
                    return False, f"Upload {i} failed: {st}"
                st, tb, _ = harness.request(
                    '/api/thumb?' + urlencode({'scope': 'private', 'path': fname, 's': 256}),
                    token=token
                )
                if st != 200 or tb != valid_webp_bytes:
                    return False, f"Thumb retrieval {i} failed: {st}"
                return True, "OK"

            with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
                futures = [executor.submit(stress_worker, i) for i in range(10)]
                for f in concurrent.futures.as_completed(futures):
                    ok, msg = f.result()
                    assert ok, msg

            # -------------------------------------------------------------
            # TEST 10: Adversarial Edge Cases
            # -------------------------------------------------------------
            print("10. Testing adversarial edge cases (re-upload, user isolation, thumb field alias, base64 whitespace)...")
            # 10a. User isolation: User 2 cannot access User 1's private thumbnail
            status, _, _ = harness.request(
                '/api/thumb?' + urlencode({'scope': 'private', 'path': 'clip1.mp4', 's': 256}),
                token=user2_token
            )
            assert status in (403, 404), f"User isolation breached! Expected 403/404, got {status}"

            # 10b. Multipart with 'thumb' field alias instead of 'thumbnail'
            initial_ffmpeg = harness.get_ffmpeg_call_count()
            status, _, _ = upload_multipart('alias_clip.mp4', sample_mp4_bytes, valid_webp_bytes, thumb_field="thumb")
            assert status == 201
            assert harness.get_ffmpeg_call_count() == initial_ffmpeg, "FFmpeg spawned on 'thumb' alias upload!"
            status, tb, _ = harness.request('/api/thumb?' + urlencode({'scope': 'private', 'path': 'alias_clip.mp4', 's': 256}), token=token)
            assert status == 200 and tb == valid_webp_bytes

            # 10c. Base64 header with leading and trailing linear whitespace
            padded_b64 = f"   \t  {valid_webp_b64}   \t  "
            initial_ffmpeg = harness.get_ffmpeg_call_count()
            status, resp_body = upload_chunked('padded_clip.mp4', sample_mp4_bytes, padded_b64, chunk_size=512)
            assert status == 201
            assert harness.get_ffmpeg_call_count() == initial_ffmpeg, "FFmpeg spawned on padded base64 chunked upload!"
            status, tb, _ = harness.request('/api/thumb?' + urlencode({'scope': 'private', 'path': 'padded_clip.mp4', 's': 256}), token=token)
            print(f"   [10c padded_b64] thumb status={status}, len={len(tb)}")
            assert status == 200 and tb == valid_webp_bytes, f"10c failed: status={status}, len={len(tb)}"

            # 10d. Re-upload / replacement: Uploading video with new thumbnail updates existing thumbnail
            sample_webp2 = root / 'sample2.webp'
            cmd = ['ffmpeg', '-y', '-f', 'lavfi', '-i', 'color=c=red:size=64x64:duration=1', '-vframes', '1', '-c:v', 'libwebp', '-quality', '85', str(sample_webp2)]
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            webp2_bytes = sample_webp2.read_bytes()
            assert webp2_bytes != valid_webp_bytes

            initial_ffmpeg = harness.get_ffmpeg_call_count()
            status, _, _ = upload_multipart('clip1.mp4', sample_mp4_bytes, webp2_bytes)
            assert status == 201
            assert harness.get_ffmpeg_call_count() == initial_ffmpeg, "FFmpeg spawned on re-upload!"
            status, tb, _ = harness.request('/api/thumb?' + urlencode({'scope': 'private', 'path': 'clip1.mp4', 's': 256}), token=token)
            assert status == 200
            assert tb == webp2_bytes, "Re-upload did not update cached thumbnail to new WebP!"
            print("   -> PASS: All adversarial edge cases verified successfully.")

            shutil.rmtree(tmp_dir, ignore_errors=True)
    finally:
        harness.stop()


def main():
    print("=================================================================")
    print(" Starting Empirical Challenge: Backend Video Thumbnail Ingestion")
    print("=================================================================")

    start_time = time.time()
    # Test both storage modes: hash_files=True and hash_files=False
    run_tests_for_mode(hash_files=True)
    run_tests_for_mode(hash_files=False)

    elapsed = time.time() - start_time
    print("\n=================================================================")
    print(f" ALL CHALLENGE TESTS PASSED across all modes in {elapsed:.2f}s")
    print("=================================================================")


if __name__ == '__main__':
    main()
