#!/usr/bin/env bash
set -euo pipefail

# Update package list
sudo apt-get update

# Install dependencies
sudo apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    libzstd-dev \
    git-lfs \
    python3-venv \
    pkg-config

# Initialize Git LFS (ignore errors if already set up)
git lfs install || true
