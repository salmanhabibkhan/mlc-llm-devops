#!/bin/bash
# Development Environment Setup Script for MLC-LLM
# Automates the setup process for local development

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PYTHON_VERSION="3.11"
VENV_DIR="venv"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MLC-LLM Development Environment Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Function to print status messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Check if script is run from project root
if [ ! -f "Dockerfile" ] || [ ! -f ".github/workflows/ci-cd.yml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

print_status "Running from project root"

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    print_status "Detected OS: Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    print_status "Detected OS: macOS"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
    print_status "Detected OS: Windows"
else
    print_error "Unsupported OS: $OSTYPE"
    exit 1
fi

# Check for required tools
print_info "Checking for required tools..."

check_command() {
    if command -v $1 &> /dev/null; then
        print_status "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

MISSING_TOOLS=()

if ! check_command python3; then
    MISSING_TOOLS+=("python3")
fi

if ! check_command git; then
    MISSING_TOOLS+=("git")
fi

if ! check_command cmake; then
    MISSING_TOOLS+=("cmake")
fi

if ! check_command rustc; then
    MISSING_TOOLS+=("rust")
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    print_error "Missing required tools: ${MISSING_TOOLS[*]}"
    print_info "Please install them before continuing"
    
    if [ "$OS" == "linux" ]; then
        print_info "Ubuntu/Debian: sudo apt-get install python3 git cmake"
        print_info "Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    elif [ "$OS" == "macos" ]; then
        print_info "macOS: brew install python@3.11 git cmake rust"
    fi
    exit 1
fi

# Initialize Git submodules
print_info "Initializing Git submodules..."
if [ -d ".git" ]; then
    git submodule update --init --recursive
    print_status "Submodules initialized"
else
    print_info "Not a git repository, skipping submodule init"
fi

# Create Python virtual environment
print_info "Creating Python virtual environment..."
if [ -d "$VENV_DIR" ]; then
    print_info "Virtual environment already exists at $VENV_DIR"
    read -p "Remove and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$VENV_DIR"
        python3 -m venv "$VENV_DIR"
        print_status "Virtual environment recreated"
    fi
else
    python3 -m venv "$VENV_DIR"
    print_status "Virtual environment created"
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
print_status "Virtual environment activated"

# Upgrade pip
print_info "Upgrading pip..."
pip install --upgrade pip setuptools wheel --quiet
print_status "Pip upgraded"

# Install development dependencies
print_info "Installing development dependencies..."
pip install --quiet \
    pytest \
    pytest-cov \
    pytest-xdist \
    pytest-timeout \
    black \
    flake8 \
    isort \
    mypy \
    pre-commit

print_status "Development dependencies installed"

# Install pre-commit hooks
print_info "Setting up pre-commit hooks..."
if [ -f ".pre-commit-config.yaml" ]; then
    pre-commit install
    print_status "Pre-commit hooks installed"
else
    print_info "No pre-commit config found, skipping"
fi

# Create necessary directories
print_info "Creating project directories..."
mkdir -p build dist logs

print_status "Directory structure created"

# Print summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Activate the virtual environment:"
echo -e "   ${GREEN}source $VENV_DIR/bin/activate${NC}"
echo -e ""
echo -e "2. Build MLC-LLM:"
echo -e "   ${GREEN}cd build${NC}"
echo -e "   ${GREEN}python ../cmake/gen_cmake_config.py${NC}"
echo -e "   ${GREEN}cmake .. && make -j\$(nproc)${NC}"
echo -e ""
echo -e "3. Install Python package:"
echo -e "   ${GREEN}cd ../python && pip install -e .${NC}"
echo -e ""
echo -e "4. Run tests:"
echo -e "   ${GREEN}pytest tests/${NC}"
echo -e ""
echo -e "5. Build Docker image:"
echo -e "   ${GREEN}docker build -t mlc-llm-dev .${NC}"
echo -e ""

print_info "For more information, see: docs/BUILD.md"