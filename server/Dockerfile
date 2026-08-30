# Multi-stage build for Crowley's Cloud Server

# Stage 1: Build Web Client Frontend (Svelte SPA)
FROM node:22-alpine AS web-builder
WORKDIR /app/server/web
COPY server/web/package*.json ./
RUN npm ci
COPY server/web/ ./
COPY server/public/ ../public/
RUN npm run build

# Stage 2: Build C++ Server Backend
FROM ubuntu:22.04 AS builder

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies (cached layer — changes rarely)
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libssl-dev \
    libsqlite3-dev \
    zlib1g-dev \
    protobuf-compiler \
    libprotobuf-dev \
    pkg-config \
    uuid-dev \
    libbrotli-dev \
    libjsoncpp-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy CMake configuration first to cache the Drogon fetch step.
# This layer is invalidated only when CMakeLists.txt changes.
COPY server/CMakeLists.txt ./server/CMakeLists.txt

# Run CMake configure to download and build Drogon (most expensive step).
# This is cached as long as CMakeLists.txt hasn't changed.
WORKDIR /app/server
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release || true

# Now copy the actual source code and proto definitions
WORKDIR /app
COPY server/ ./server/
COPY proto/ ./proto/

# Re-run configure (picks up new source files) and build
WORKDIR /app/server
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build -j$(nproc)

# Stage 3: Runtime environment
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime libraries (not -dev packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    libsqlite3-0 \
    zlib1g \
    libprotobuf23 \
    libuuid1 \
    libbrotli1 \
    libjsoncpp25 \
    ffmpeg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the built binary and the default configurations
COPY --from=builder /app/server/build/crowleys_cloud_server ./crowleys_cloud_server
COPY --from=builder /app/server/config ./config

# Copy compiled static web client files
COPY --from=web-builder /app/server/public ./public

# Create default directories for volume mounts
RUN mkdir -p storage uploads logs data

# Expose server port
EXPOSE 8080

# Run the server
CMD ["./crowleys_cloud_server"]
