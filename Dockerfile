# Multipurpose Docker Image for MLC-LLM Development and Building
# Supports both interactive development and CI/CD builds

ARG BASE_IMAGE=nvidia/cuda:12.8.0-devel-ubuntu22.04
FROM ${BASE_IMAGE}

# Build arguments
ARG PYTHON_VERSION=3.11
ARG CMAKE_VERSION=3.28.1
ARG DEBIAN_FRONTEND=noninteractive

# Labels
LABEL maintainer="DevOps Team"
LABEL description="MLC-LLM Development and Build Environment"
LABEL version="1.0"

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC

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
    # Development tools
    vim \
    nano \
    htop \
    tree \
    jq \
    # Python dependencies
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
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

# Install CMake
RUN wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz -C /usr/local --strip-components=1 && \
    rm cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz

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

# Set up working directory
WORKDIR /workspace

# Copy entrypoint script
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

# Default command (can be overridden)
CMD ["/bin/bash"]