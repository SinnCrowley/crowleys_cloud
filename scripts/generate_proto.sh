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
DART_PLUGIN="$HOME/.pub-cache/bin/protoc-gen-dart"
if [ ! -f "$DART_PLUGIN" ]; then
    echo "Dart protoc-gen-dart plugin not found at $DART_PLUGIN. Activating..."
    dart pub global activate protoc_plugin
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
