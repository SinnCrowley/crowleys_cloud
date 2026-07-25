# Multi-stage build for Crowley's Cloud Server
# Stage 1: Build environment
FROM ubuntu:22.04 AS builder

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
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

# Copy the server source code and the proto directory (needed by CMake)
COPY server/ ./server/
COPY proto/ ./proto/

# Build the server
WORKDIR /app/server
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build -j$(nproc)

# Stage 2: Runtime environment
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl3 \
    libsqlite3-0 \
    zlib1g \
    libprotobuf-dev \
    uuid \
    libbrotli1 \
    libjsoncpp-dev \
    ffmpeg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the built binary and the default configurations
COPY --from=builder /app/server/build/crowleys_cloud_server ./crowleys_cloud_server
COPY --from=builder /app/server/config ./config

# Create default directories for volume mounts
RUN mkdir -p storage uploads logs data

# Expose server port
EXPOSE 8080

# Run the server
CMD ["./crowleys_cloud_server"]
