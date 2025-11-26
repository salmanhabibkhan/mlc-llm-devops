#!/usr/bin/env bash
set -eux

sudo apt update
sudo apt install -y \
    git \
    python3-dev \
    python3-pip \
    ninja-build \
    build-essential \
    cmake
