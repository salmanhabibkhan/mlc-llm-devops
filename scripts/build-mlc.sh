#!/bin/bash
# Non-interactive build script for MLC-LLM
# Works in Docker (macOS/Windows/Linux)
# CPU-only enforced inside Docker

set -e

# ===========================
# Pretty Colors
# ===========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE} MLC-LLM Non-Interactive Build${NC}"
echo -e "${BLUE}======================================${NC}\n"

# ===========================
# Detect Platform
# ===========================
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64) echo "x64" ;;
        arm64|aarch64) echo "arm64" ;;
        *) echo "$ARCH" ;;
    esac
}

# ===========================
# Configure Build Backends
# ===========================
configure_backends() {
    local platform=$1

    USE_CUDA=OFF
    USE_ROCM=OFF
    USE_VULKAN=OFF
    USE_METAL=OFF
    USE_OPENCL=OFF

    if [ -f /.dockerenv ]; then
        echo -e "${YELLOW}Docker detected → Forcing CPU-only${NC}"
        USE_VULKAN=OFF
        USE_METAL=OFF
    else
        if [[ "$platform" == "macos" ]]; then
            echo -e "${GREEN}macOS detected: Enabling Metal${NC}"
            USE_METAL=ON
        fi
    fi

    export USE_CUDA USE_ROCM USE_VULKAN USE_METAL USE_OPENCL
}

# ===========================
# Verify Source Directory
# ===========================
check_source() {
    if [[ ! -f "CMakeLists.txt" ]] || [[ ! -d "python" ]]; then
        echo -e "${RED}ERROR: Run script from project root${NC}"
        exit 1
    fi
}

# ===========================
# Generate CMake Config
# ===========================
generate_cmake_config() {
    mkdir -p cmake
    cat > cmake/config.cmake << EOF
set(USE_CUDA ${USE_CUDA} CACHE BOOL "")
set(USE_ROCM ${USE_ROCM} CACHE BOOL "")
set(USE_VULKAN ${USE_VULKAN} CACHE BOOL "")
set(USE_METAL ${USE_METAL} CACHE BOOL "")
set(USE_OPENCL ${USE_OPENCL} CACHE BOOL "")
set(CMAKE_BUILD_TYPE Release CACHE STRING "")
EOF
}

# ===========================
# Build C++ Core
# ===========================
build_cpp() {
    rm -rf build
    mkdir build
    cd build

    cmake .. -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_VULKAN=${USE_VULKAN} \
        -DUSE_METAL=${USE_METAL} \
        -DUSE_CUDA=${USE_CUDA} \
        -DUSE_OPENCL=${USE_OPENCL}

    cmake --build . --parallel $(nproc)
    cd ..
}

# ===========================
# Build Python Wheel
# ===========================
build_python() {
    cd python
    pip install --upgrade build wheel setuptools
    python -m build
    cd ..
}

# ===========================
# Install Python Wheel
# ===========================
install_python() {
    echo -e "${YELLOW}Installing Python package (editable)...${NC}"

    # Ensure version.py exists
    if [[ ! -f "version.py" ]]; then
        echo -e "${GREEN}Creating version.py${NC}"
        echo "__version__ = '0.1.dev0'" > version.py
    fi

    cd python

    # Editable install (wheel build fails for mlc-llm)
    pip install -e .

    cd ..
}
# ===========================
# Verify Python Import
# ===========================
verify_python() {
    echo -e "${YELLOW}Verifying Python import...${NC}"
    python - << 'EOF'
import sys
try:
    import mlc_llm
    print("✓ mlc_llm imported OK")
    print("Version:", getattr(mlc_llm, "__version__", "unknown"))
    print("Location:", mlc_llm.__file__)
except Exception as e:
    print("✗ Import error:", e)
    sys.exit(1)
EOF
}

# ===========================
# MAIN
# ===========================
main() {
    PLATFORM=$(detect_platform)
    ARCH=$(detect_arch)

    echo -e "${YELLOW}Platform: $PLATFORM${NC}"
    echo -e "${YELLOW}Architecture: $ARCH${NC}\n"

    check_source
    configure_backends "$PLATFORM"
    generate_cmake_config
    build_cpp
    build_python
    install_python
    verify_python

    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}Build + Installation Completed ✓${NC}"
    echo -e "${GREEN}======================================${NC}"
}

main
