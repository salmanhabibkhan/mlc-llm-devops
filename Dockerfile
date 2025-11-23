# Multi-Architecture Dockerfile for MLC-LLM Development and Building
# Supports: linux/amd64, linux/arm64, darwin/arm64 (Apple Silicon)

ARG TARGETPLATFORM=linux/amd64
ARG BUILDPLATFORM=linux/amd64

# Use appropriate base image based on platform
FROM --platform=${TARGETPLATFORM} ubuntu:22.04 AS base

# Build arguments
ARG PYTHON_VERSION=3.11
ARG CMAKE_VERSION=3.28.1
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

# Labels
LABEL maintainer="DevOps Team"
LABEL description="MLC-LLM Multi-Architecture Development Environment"
LABEL version="2.0"
LABEL platforms="linux/amd64,linux/arm64"

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    gcc \
    g++ \
    make \
    git \
    git-lfs \
    wget \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    pkg-config \
    # Development tools
    vim \
    nano \
    htop \
    tree \
    jq \
    # Python dependencies
    software-properties-common \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    # Additional build dependencies
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    # LLVM dependencies
    libzstd-dev \
    libedit-dev \
    ninja-build \
    ccache \
    && rm -rf /var/lib/apt/lists/*

# Install CMake (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then CMAKE_ARCH="x86_64"; \
    elif [ "$ARCH" = "arm64" ]; then CMAKE_ARCH="aarch64"; \
    else CMAKE_ARCH="x86_64"; fi && \
    wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}.tar.gz && \
    tar -xzf cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}.tar.gz -C /usr/local --strip-components=1 && \
    rm cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}.tar.gz

# Install Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . $HOME/.cargo/env && \
    rustup default stable

ENV PATH="/root/.cargo/bin:${PATH}"

# Create symbolic links for Python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1

# Upgrade pip and install Python build tools
RUN python -m pip install --upgrade pip setuptools wheel

# Install Python development dependencies
RUN pip install --no-cache-dir \
    pytest \
    pytest-cov \
    pytest-xdist \
    black \
    flake8 \
    mypy \
    isort \
    pylint \
    pre-commit \
    build \
    twine \
    numpy \
    scipy

# Vulkan SDK
RUN apt-get update && apt-get install -y \
    libvulkan-dev \
    vulkan-tools \
    mesa-vulkan-drivers \
    glslang-tools \
    spirv-tools \
 && rm -rf /var/lib/apt/lists/*


# Set up working directory
WORKDIR /workspace

# Copy configuration files
COPY cmake-config-presets/ /root/.mlc-cmake-presets/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set environment variables for MLC-LLM
ENV MLC_LLM_SOURCE_DIR=/workspace \
    PYTHONPATH=/workspace/python:${PYTHONPATH}

# Expose common ports
EXPOSE 8000 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)" || exit 1

# Entry point
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["/bin/bash"]