#!/bin/bash
set -e

# Directories
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO_DIR="$PROJECT_ROOT/proto"
DART_OUT_DIR="$PROJECT_ROOT/lib/shared/proto"
CPP_OUT_DIR="$PROJECT_ROOT/server/build/proto_gen"

echo "Creating output directories..."
mkdir -p "$DART_OUT_DIR"
mkdir -p "$CPP_OUT_DIR"

# Check protoc
if ! command -v protoc &> /dev/null; then
    echo "Error: protoc is not installed."
    exit 1
fi

# Locate Dart plugin
export PATH="$HOME/.pub-cache/bin:$PATH"

if ! command -v protoc-gen-dart &> /dev/null && [ ! -f "$HOME/.pub-cache/bin/protoc-gen-dart" ]; then
    echo "Dart protoc-gen-dart plugin not found. Activating..."
    dart pub global activate protoc_plugin
fi

DART_PLUGIN="$(command -v protoc-gen-dart 2>/dev/null || echo "$HOME/.pub-cache/bin/protoc-gen-dart")"

# Validate that protoc-gen-dart does not produce stdout diagnostics due to snapshot mismatch
TEST_OUTPUT=$(echo "" | "$DART_PLUGIN" 2>&1 || true)
if echo "$TEST_OUTPUT" | grep -q "Resolving dependencies"; then
    echo "Detected outdated protoc_plugin snapshot. Recompiling..."
    dart pub global deactivate protoc_plugin 2>/dev/null || true
    dart pub global activate protoc_plugin
    DART_PLUGIN="$(command -v protoc-gen-dart 2>/dev/null || echo "$HOME/.pub-cache/bin/protoc-gen-dart")"
fi

echo "Generating Dart classes..."
protoc --dart_out="$DART_OUT_DIR" \
       --plugin=protoc-gen-dart="$DART_PLUGIN" \
       -I="$PROTO_DIR" \
       "$PROTO_DIR"/*.proto

echo "Generating C++ classes..."
protoc --cpp_out="$CPP_OUT_DIR" \
       -I="$PROTO_DIR" \
       "$PROTO_DIR"/*.proto

echo "Protobuf code generation completed successfully!"
