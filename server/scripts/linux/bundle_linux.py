#!/usr/bin/env python3
# Copyright (C) 2026 Sinn Crowley
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

"""
Bundle non-system dynamic shared libraries for Linux portable distribution.
Resolves transitive dependencies via ldd, copies libraries to lib/, and sets RPATH with patchelf.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# System libraries that must be provided by the host glibc / C++ runtime
SYSTEM_PATTERNS = [
    r'^linux-vdso\.so',
    r'^ld-linux',
    r'^libc\.so',
    r'^libm\.so',
    r'^libmvec\.so',
    r'^libdl\.so',
    r'^libpthread\.so',
    r'^librt\.so',
    r'^libresolv\.so',
    r'^libutil\.so',
    r'^libnss_',
    r'^libgcc_s\.so',
    r'^libstdc\+\+\.so',
]


def is_system_lib(name: str) -> bool:
    for pattern in SYSTEM_PATTERNS:
        if re.search(pattern, name):
            return True
    return False


def get_soname(file_path: Path, patchelf_bin: str | None) -> str | None:
    if patchelf_bin and file_path.is_file():
        try:
            res = subprocess.check_output(
                [patchelf_bin, "--print-soname", str(file_path)],
                stderr=subprocess.DEVNULL
            ).decode('utf-8', errors='replace').strip()
            if res:
                return res
        except subprocess.CalledProcessError:
            pass
    return None


def get_dependencies(file_path: Path) -> dict[str, Path]:
    """Run ldd on a binary/library and return a mapping of libname -> resolved path."""
    deps = {}
    try:
        output = subprocess.check_output(
            ['ldd', str(file_path)],
            stderr=subprocess.DEVNULL,
            env=dict(os.environ, LC_ALL='C')
        ).decode('utf-8', errors='replace')
    except (subprocess.CalledProcessError, FileNotFoundError):
        return deps

    for line in output.splitlines():
        line = line.strip()
        # Case 1: libname.so.X => /path/to/lib (0x...)
        m = re.match(r'^([^\s]+)\s*=>\s*([^\s]+)', line)
        if m:
            name, path_str = m.group(1), m.group(2)
            if path_str != 'not' and os.path.isabs(path_str):
                p = Path(path_str)
                if p.exists():
                    deps[name] = p
            continue

        # Case 2: /lib64/ld-linux-x86-64.so.2 (0x...)
        m = re.match(r'^(/[^\s]+)', line)
        if m:
            p = Path(m.group(1))
            if p.exists():
                deps[p.name] = p

    return deps


def bundle(executable: Path, lib_dir: Path):
    executable = executable.resolve()
    if not executable.exists():
        print(f"[ERROR] Executable not found: {executable}", file=sys.stderr)
        sys.exit(1)

    lib_dir.mkdir(parents=True, exist_ok=True)
    patchelf_bin = shutil.which("patchelf")

    copied_canonical = set()
    queue = [executable]
    all_libs_in_dir = set()

    print(f"[BUNDLE] Inspecting dependencies for {executable}...")

    while queue:
        current = queue.pop(0)
        deps = get_dependencies(current)

        for requested_name, target_path in deps.items():
            if is_system_lib(requested_name) or is_system_lib(target_path.name):
                continue

            real_path = target_path.resolve()
            canonical_name = real_path.name
            dest_real = lib_dir / canonical_name

            # Copy canonical library if not already copied
            if real_path.parent != lib_dir and real_path not in copied_canonical and not dest_real.exists():
                print(f"  -> Bundling: {canonical_name} (from {real_path})")
                shutil.copy2(real_path, dest_real)
                dest_real.chmod(0o755)
                copied_canonical.add(real_path)
                all_libs_in_dir.add(dest_real)
                # Queue this newly copied library to discover transitive dependencies
                queue.append(dest_real)
            elif dest_real.exists():
                all_libs_in_dir.add(dest_real)

            # Recreate requested symlink if needed (e.g. libprotobuf.so.32 -> libprotobuf.so.32.0.4)
            if requested_name != canonical_name:
                link_dest = lib_dir / requested_name
                if not link_dest.exists() and not link_dest.is_symlink():
                    link_dest.symlink_to(canonical_name)
                    print(f"     Symlink: {requested_name} -> {canonical_name}")

            # Recreate target_path basename symlink if different
            if target_path.name != canonical_name and target_path.name != requested_name:
                link_dest = lib_dir / target_path.name
                if not link_dest.exists() and not link_dest.is_symlink():
                    link_dest.symlink_to(canonical_name)

            # Recreate DT_SONAME symlink if different
            soname = get_soname(dest_real, patchelf_bin)
            if soname and soname != canonical_name and soname != requested_name:
                link_dest = lib_dir / soname
                if not link_dest.exists() and not link_dest.is_symlink():
                    link_dest.symlink_to(canonical_name)

    # Patch RPATH with patchelf if available
    if patchelf_bin:
        print("[BUNDLE] Configuring RPATH with patchelf...")
        try:
            executable.chmod(0o755)
            subprocess.run([patchelf_bin, "--set-rpath", "$ORIGIN/lib:$ORIGIN", str(executable)], check=True)
            print(f"  -> Set RPATH on executable: $ORIGIN/lib:$ORIGIN")
        except subprocess.CalledProcessError as e:
            print(f"[WARN] Failed to set RPATH on executable: {e}", file=sys.stderr)

        for lib_file in all_libs_in_dir:
            try:
                lib_file.chmod(0o755)
                subprocess.run([patchelf_bin, "--set-rpath", "$ORIGIN", str(lib_file)], check=True)
            except subprocess.CalledProcessError:
                pass
        print(f"[BUNDLE] Successfully patched {len(all_libs_in_dir)} libraries.")
    else:
        print("[WARN] patchelf not found; relying on link-time RPATH and LD_LIBRARY_PATH wrapper.")

    print(f"[BUNDLE] Successfully bundled {len(copied_canonical)} libraries into {lib_dir}")


def main():
    parser = argparse.ArgumentParser(description="Bundle non-system dependencies for Linux release.")
    parser.add_argument("--executable", required=True, type=Path, help="Path to staged executable.")
    parser.add_argument("--lib-dir", type=Path, default=None, help="Directory to store bundled libraries.")
    args = parser.parse_args()

    lib_dir = args.lib_dir
    if lib_dir is None:
        lib_dir = args.executable.parent / "lib"

    bundle(args.executable, lib_dir)


if __name__ == "__main__":
    main()
