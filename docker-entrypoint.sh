#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}MLC-LLM Docker Environment${NC}"
echo -e "${GREEN}======================================${NC}"

# Display environment information
echo -e "${YELLOW}Python Version:${NC} $(python --version)"
echo -e "${YELLOW}CMake Version:${NC} $(cmake --version | head -n1)"
echo -e "${YELLOW}Rust Version:${NC} $(rustc --version)"
echo -e "${YELLOW}CUDA Version:${NC} $(nvcc --version 2>/dev/null | grep release || echo 'Not available')"
echo -e "${YELLOW}Working Directory:${NC} $(pwd)"

# Check if MLC-LLM source exists
check_mlc_source() {
    if [ -f "/workspace/setup.py" ] || [ -f "/workspace/pyproject.toml" ] || [ -f "/workspace/CMakeLists.txt" ]; then
        return 0
    else
        return 1
    fi
}

# Check if we're in build mode (CI/CD) or development mode
if [ "$BUILD_MODE" = "true" ]; then
    echo -e "${GREEN}Running in BUILD MODE${NC}"
    
    # Clone repository if not present
    if ! check_mlc_source; then
        echo -e "${YELLOW}Cloning MLC-LLM repository...${NC}"
        rm -rf /workspace/*
        git clone --recursive https://github.com/mlc-ai/mlc-llm.git /tmp/mlc-llm
        mv /tmp/mlc-llm/* /workspace/
        mv /tmp/mlc-llm/.git /workspace/ 2>/dev/null || true
        cd /workspace
        git submodule update --init --recursive
    fi
    
    # Run build steps
    echo -e "${YELLOW}Starting build process...${NC}"
    
    # Create build directory
    mkdir -p /workspace/build
    cd /workspace/build
    
    # Generate build configuration
    echo -e "${YELLOW}Generating CMake configuration...${NC}"
    python ../cmake/gen_cmake_config.py
    
    # Build MLC-LLM libraries
    echo -e "${YELLOW}Building MLC-LLM libraries...${NC}"
    cmake .. -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_CUDA=OFF \
        -DUSE_OPENCL=OFF \
        -DUSE_VULKAN=ON
    cmake --build . --parallel $(nproc)
    
    # Install Python package
    cd /workspace/python
    echo -e "${YELLOW}Installing Python package...${NC}"
    pip install -e .
    
    # Validate installation
    echo -e "${YELLOW}Validating installation...${NC}"
    python -c "import mlc_llm; print(f'MLC-LLM version: {getattr(mlc_llm, \"__version__\", \"dev\")}')"
    
    echo -e "${GREEN}Build completed successfully!${NC}"
    
    # If additional command is provided, execute it
    if [ $# -gt 0 ]; then
        exec "$@"
    fi
else
    echo -e "${GREEN}Running in DEVELOPMENT MODE${NC}"
    
    # Check if source is mounted or needs to be cloned
    if ! check_mlc_source; then
        echo -e "${YELLOW}MLC-LLM source not found in /workspace${NC}"
        echo -e "${YELLOW}Options:${NC}"
        echo -e "  1. Mount source: ${GREEN}docker run -v /path/to/mlc-llm:/workspace ...${NC}"
        echo -e "  2. Auto-clone: Set ${GREEN}AUTO_CLONE=true${NC} environment variable"
        echo -e "  3. Clone manually inside container: ${GREEN}git clone --recursive https://github.com/mlc-ai/mlc-llm.git .${NC}"
        
        # Auto-clone if requested
        if [ "$AUTO_CLONE" = "true" ]; then
            echo -e "${YELLOW}AUTO_CLONE enabled, cloning repository...${NC}"
            git clone --recursive https://github.com/mlc-ai/mlc-llm.git /tmp/mlc-llm
            mv /tmp/mlc-llm/* /workspace/
            mv /tmp/mlc-llm/.git /workspace/ 2>/dev/null || true
            cd /workspace
            git submodule update --init --recursive
            echo -e "${GREEN}Repository cloned successfully!${NC}"
        else
            echo -e "${YELLOW}Starting shell in empty workspace...${NC}"
        fi
    else
        echo -e "${GREEN}Source code detected${NC}"
        
        # Set up development environment
        if [ -d "/workspace/python" ]; then
            export PYTHONPATH="/workspace/python:${PYTHONPATH}"
            echo -e "${YELLOW}PYTHONPATH set to:${NC} ${PYTHONPATH}"
        fi
    fi
    
    # Execute the provided command or start interactive shell
    if [ $# -gt 0 ]; then
        exec "$@"
    else
        echo -e "${YELLOW}Starting interactive bash shell...${NC}"
        echo -e "${YELLOW}Type 'exit' to quit${NC}"
        echo ""
        echo -e "${GREEN}Quick commands:${NC}"
        echo -e "  ${GREEN}# Clone MLC-LLM:${NC}"
        echo -e "  git clone --recursive https://github.com/mlc-ai/mlc-llm.git ."
        echo -e "  ${GREEN}# Build:${NC}"
        echo -e "  mkdir build && cd build && python ../cmake/gen_cmake_config.py && cmake .. && make -j\$(nproc)"
        echo ""
        exec /bin/bash
    fi
fi