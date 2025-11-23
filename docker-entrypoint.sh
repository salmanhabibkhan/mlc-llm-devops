#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN} MLC-LLM Docker Environment${NC}"
echo -e "${GREEN}======================================${NC}"

# System Info
echo -e "${YELLOW}Python Version:${NC} $(python --version 2>&1)"
echo -e "${YELLOW}CMake Version:${NC} $(cmake --version | head -n1)"
echo -e "${YELLOW}Rust Version:${NC} $(rustc --version 2>/dev/null || echo 'Not available')"
echo -e "${YELLOW}CUDA Version:${NC} $(nvcc --version 2>/dev/null | grep release || echo 'Not available')"
echo -e "${YELLOW}Working Directory:${NC} $(pwd)"

# Detect source
check_mlc_source() {
    [[ -f "/workspace/CMakeLists.txt" || -f "/workspace/pyproject.toml" || -f "/workspace/setup.py" ]]
}

safe_clone() {
    local REPO_URL="https://github.com/mlc-ai/mlc-llm.git"
    local TMP_DIR="/tmp/mlc-llm"

    echo -e "${YELLOW}Cloning MLC-LLM repository...${NC}"

    rm -rf "$TMP_DIR" /workspace/*
    git clone --recursive "$REPO_URL" "$TMP_DIR"

    # Move into workspace
    shopt -s dotglob
    mv "$TMP_DIR"/* /workspace/
    mv "$TMP_DIR"/.git /workspace/ || true
    shopt -u dotglob

    rm -rf "$TMP_DIR"
    cd /workspace
    git submodule update --init --recursive
}

# -----------------------
# BUILD MODE
# -----------------------
if [[ "${BUILD_MODE:-false}" == "true" ]]; then
    echo -e "${GREEN}Running in BUILD MODE${NC}"

    # Clone if missing
    if ! check_mlc_source; then
        safe_clone
    else
        echo -e "${GREEN}Source detected, skipping clone.${NC}"
    fi

    echo -e "${YELLOW}Starting build process...${NC}"

    cd /workspace

    # Preferred build script
    if [[ -f "scripts/build-mlc.sh" ]]; then
        chmod +x scripts/build-mlc.sh
        ./scripts/build-mlc.sh
    else
        echo -e "${YELLOW}No build script found. Running fallback CMake build...${NC}"

        mkdir -p build
        cd build

        # Copy preset if available
        if [[ -f "/root/.mlc-cmake-presets/config.cmake" ]]; then
            cp /root/.mlc-cmake-presets/config.cmake ../cmake/config.cmake
        fi

        # Platform detection
        if [[ "$(uname)" == "Darwin" ]]; then
            cmake .. -GNinja \
                -DCMAKE_BUILD_TYPE=Release \
                -DUSE_METAL=ON \
                -DUSE_VULKAN=OFF \
                -DUSE_CUDA=OFF
        else
            cmake .. -GNinja \
                -DCMAKE_BUILD_TYPE=Release \
                -DUSE_CUDA=OFF \
                -DUSE_OPENCL=OFF \
                -DUSE_VULKAN=ON
        fi

        cmake --build . --parallel "$(nproc)"
    fi

    # Install Python package
    cd /workspace/python
    echo -e "${YELLOW}Installing Python package...${NC}"
    pip install -e .

    # Validate
    echo -e "${YELLOW}Validating installation...${NC}"
    python - <<'EOF'
import mlc_llm
print("MLC-LLM version:", getattr(mlc_llm, "__version__", "dev"))
EOF

    echo -e "${GREEN}Build completed successfully!${NC}"

    exec "$@" || exit 0
fi

# -----------------------
# DEVELOPMENT MODE
# -----------------------
echo -e "${GREEN}Running in DEVELOPMENT MODE${NC}"

if ! check_mlc_source; then
    echo -e "${YELLOW}MLC-LLM source not found in /workspace${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  1. Mount source: ${GREEN}docker run -v /path/to/mlc-llm:/workspace ...${NC}"
    echo -e "  2. Auto-clone:  ${GREEN}AUTO_CLONE=true${NC}"
    echo -e "  3. Manual clone: ${GREEN}git clone --recursive https://github.com/mlc-ai/mlc-llm.git .${NC}"

    if [[ "${AUTO_CLONE:-false}" == "true" ]]; then
        safe_clone
        echo -e "${GREEN}Repository cloned successfully!${NC}"
    else
        echo -e "${YELLOW}Starting shell in empty workspace...${NC}"
    fi
else
    echo -e "${GREEN}Source detected${NC}"
    if [[ -d "/workspace/python" ]]; then
        export PYTHONPATH="/workspace/python:${PYTHONPATH}"
        echo -e "${YELLOW}PYTHONPATH updated:${NC} ${PYTHONPATH}"
    fi
fi

# Open interactive shell unless args were given
if [[ $# -gt 0 ]]; then
    exec "$@"
else
    echo -e "${YELLOW}Starting interactive bash shell...${NC}"
    echo -e "${YELLOW}Quick commands:${NC}"
    echo -e "  ${GREEN}git clone --recursive https://github.com/mlc-ai/mlc-llm.git .${NC}"
    echo -e "  ${GREEN}mkdir build && cd build && python ../cmake/gen_cmake_config.py && cmake .. && make -j\$(nproc)${NC}"
    exec /bin/bash
fi
