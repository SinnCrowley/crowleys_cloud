#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Crowley's Cloud Server — Universal Binary Bundle Creator for macOS
# Combines an ARM64 staged directory and an x86_64 staged directory into a
# single fat/universal Mach-O bundle supporting both Apple Silicon and Intel.
# ==============================================================================

ARM64_DIR="${1:?Usage: $0 <arm64_dir> <x64_dir> <output_dir>}"
X64_DIR="${2:?Usage: $0 <arm64_dir> <x64_dir> <output_dir>}"
OUT_DIR="${3:?Usage: $0 <arm64_dir> <x64_dir> <output_dir>}"

if [ ! -d "$ARM64_DIR" ]; then
  echo "Error: ARM64 directory '$ARM64_DIR' does not exist." >&2
  exit 1
fi

if [ ! -d "$X64_DIR" ]; then
  echo "Error: x86_64 directory '$X64_DIR' does not exist." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "Creating Universal Binary bundle:"
echo "  ARM64 source:  $ARM64_DIR"
echo "  x86_64 source: $X64_DIR"
echo "  Destination:   $OUT_DIR"

# 1. Copy complete directory layout from ARM64 source (configs, public, scripts, symlinks)
cp -R "$ARM64_DIR"/* "$OUT_DIR"/

# Helper function to check if a regular file is a Mach-O binary
is_macho() {
  local target="$1"
  if [ -f "$target" ] && [ ! -L "$target" ]; then
    if file -b "$target" 2>/dev/null | grep -q "Mach-O"; then
      return 0
    fi
  fi
  return 1
}

# 2. Iterate through files in ARM64 directory; if Mach-O, merge with lipo
while IFS= read -r -d '' arm_file; do
  rel_path="${arm_file#$ARM64_DIR/}"
  x64_file="$X64_DIR/$rel_path"
  out_file="$OUT_DIR/$rel_path"

  if is_macho "$arm_file"; then
    if [ -f "$x64_file" ] && is_macho "$x64_file"; then
      echo "  [lipo] Merging $rel_path (arm64 + x86_64)..."
      rm -f "$out_file"
      lipo -create -output "$out_file" "$arm_file" "$x64_file"
      chmod +x "$out_file"
    else
      echo "  [warn] $rel_path not present or not Mach-O in x86_64; keeping ARM64"
    fi
  fi
done < <(find "$ARM64_DIR" -type f -print0)

# 3. Check for any x86_64-specific files not present in ARM64
while IFS= read -r -d '' x64_file; do
  rel_path="${x64_file#$X64_DIR/}"
  out_file="$OUT_DIR/$rel_path"
  if [ ! -e "$out_file" ]; then
    echo "  [copy] Adding x86_64-only file: $rel_path"
    mkdir -p "$(dirname "$out_file")"
    cp -P "$x64_file" "$out_file"
  fi
done < <(find "$X64_DIR" -type f -print0)

# 4. Ad-hoc re-sign all Mach-O binaries in output directory
echo "Re-signing Universal binaries..."
while IFS= read -r -d '' binary; do
  if is_macho "$binary"; then
    codesign --force --sign - "$binary"
  fi
done < <(find "$OUT_DIR" -type f -print0)

echo "Universal bundle created successfully at $OUT_DIR."
