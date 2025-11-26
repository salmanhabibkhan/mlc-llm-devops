#!/usr/bin/env bash
set -euo pipefail

cd mlc-official

# Create and enter the build directory
mkdir -p build
cd build

# Generate CMake config non-interactively (Enter for defaults, N for "No")
python ../cmake/gen_cmake_config.py <<'EOF'


N
N
N
N
N
N
N
EOF

# Configure the build
cmake .. -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_CUDA=OFF \
    -DUSE_OPENCL=OFF \
    -DUSE_VULKAN=ON

# Build with parallel jobs
cmake --build . --parallel "$(nproc)"

# Build Python wheels
cd ../python
python -m pip install --upgrade pip setuptools wheel build
python -m build --wheel --outdir ../dist/ || true
