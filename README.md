# MLC-LLM DevOps Pipeline

Production-ready CI/CD pipeline for building, testing, and deploying MLC-LLM across multiple platforms with full automation.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Cross-Platform Support](#cross-platform-support)
- [Docker Image](#docker-image)
- [CI/CD Pipeline](#cicd-pipeline)
- [Building from Source](#building-from-source)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## 🎯 Overview

This repository provides a **complete DevOps solution** for MLC-LLM (Machine Learning Compilation for Large Language Models). It includes:

- **Multi-architecture Docker environment** (x86_64, ARM64)
- **Automated CI/CD pipeline** with GitHub Actions
- **Non-interactive build scripts** for all platforms
- **Cross-platform wheel building** (Linux x64, Windows x64)
- **Automated testing** and release management
- **Production-ready** configuration

### What This Repo Does

```
┌──────────────────────────────────────────────────────────┐
│  This DevOps Repository                                  │
│  ├── Build Environment (Docker)                          │
│  ├── CI/CD Pipeline (GitHub Actions)                     │
│  ├── Automated Build Scripts                             │
│  └── Documentation                                       │
└──────────────────────────────────────────────────────────┘
                        │
                        │ Builds & Packages
                        ▼
┌──────────────────────────────────────────────────────────┐
│  MLC-LLM (Source from mlc-ai/mlc-llm)                    │
│  └── Python wheels for Linux & Windows                   │
└──────────────────────────────────────────────────────────┘
```

**Note**: This repo provides the **build infrastructure**. The MLC-LLM source code is automatically cloned from [mlc-ai/mlc-llm](https://github.com/mlc-ai/mlc-llm).

---

## ✨ Features

### Docker Environment
- ✅ Multi-architecture support (x86_64/AMD64, ARM64/Apple Silicon)
- ✅ Single image for development and CI/CD
- ✅ All dependencies pre-installed (Python 3.11, CMake, Rust, CUDA support)
- ✅ Smart entrypoint with auto-clone capability
- ✅ Non-interactive build mode for automation

### CI/CD Pipeline
- ✅ Test-driven deployment (tests gate all builds)
- ✅ Matrix builds for multiple platforms
- ✅ Automated wheel building (Linux x64, Windows x64)
- ✅ GitHub Container Registry (GHCR) integration
- ✅ Automatic releases on version tags
- ✅ Security scanning with Trivy

### Cross-Platform Support
- ✅ **Linux**: x86_64 and ARM64 with Vulkan/CUDA
- ✅ **Windows**: x86_64 with Vulkan/CUDA
- ✅ **macOS**: Native builds with Metal support
- ✅ Automatic backend detection (Metal/CUDA/Vulkan)

### Build Automation
- ✅ Non-interactive CMake configuration
- ✅ Platform-specific backend selection
- ✅ Parallel compilation with all CPU cores
- ✅ Comprehensive testing suite

---

## 🚀 Quick Start

### Prerequisites

- **Docker** 20.10+ (for Docker builds)
- **Git** 2.30+
- **GitHub account** (for CI/CD)

### Option 1: Docker with Auto-Clone (Easiest)

```bash
# 1. Clone this repository
git clone --recursive https://github.com/salmanhabibkhan/mlc-llm-devops.git
cd mlc-llm-devops

# 2. Build Docker image for your architecture
# For x86_64 (Intel/AMD):
docker build --platform linux/amd64 -t mlc-llm-dev:local .

# For ARM64 (Apple Silicon, Raspberry Pi):
docker build --platform linux/arm64 -t mlc-llm-dev:local .

# 3. Run with auto-clone (MLC-LLM automatically cloned)
docker run -it --rm \
  -e AUTO_CLONE=true \
  -v mlc-cache:/root/.cache \
  mlc-llm-dev:local

# 4. Inside container - build MLC-LLM (fully automated)
cd /workspace
bash scripts/build-mlc.sh

# 5. Verify installation
python -c "import mlc_llm; print('✅ Success!')"
```

**Duration**: 15-30 minutes (first build)
**Questions**: None (fully automated)

### Option 2: Native Build (Recommended for macOS)

For **Apple Silicon Mac** users to get Metal GPU acceleration:

```bash
# 1. Install dependencies
brew install cmake ninja git git-lfs python@3.11 rust

# 2. Clone MLC-LLM
git clone --recursive https://github.com/salmanhabibkhan/mlc-llm-devops.git
cd mlc-llm

# 3. Copy build script from this repo
curl -O https://github.com/salmanhabibkhan/mlc-llm-devops/main/scripts/build-mlc.sh
chmod +x build-mlc.sh

# 4. Build (auto-enables Metal for GPU)
bash build-mlc.sh

# 5. Verify
python3 -c "import mlc_llm; print('✅ Success with Metal!')"
```

### Option 3: CI/CD Pipeline

```bash
# 1. Fork/clone this repository to your GitHub

# 2. Push to main branch or create a tag
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0

# 3. GitHub Actions automatically:
#    - Builds Docker image → Pushes to GHCR
#    - Runs tests
#    - Builds wheels for Linux & Windows
#    - Creates GitHub Release with wheels
```

---

## 🌍 Cross-Platform Support

### Architecture Support Matrix

| Platform | Architecture | Docker | Native | GPU Backend | Status |
|----------|-------------|---------|---------|-------------|--------|
| **Linux** | x86_64 (Intel/AMD) | ✅ | ✅ | CUDA, Vulkan | Fully Supported |
| **Linux** | ARM64 (Raspberry Pi) | ✅ | ✅ | Vulkan | Fully Supported |
| **Windows** | x86_64 | ✅ | ✅ | CUDA, Vulkan | Fully Supported |
| **macOS** | Apple Silicon (M1/M2/M3) | ⚠️ | ✅ | Metal | Native Recommended* |
| **macOS** | Intel | ⚠️ | ✅ | Metal | Native Recommended* |

*Docker on macOS runs Linux in a VM, so Metal GPU is not available. Use native builds for GPU acceleration.

### Backend Auto-Detection

The build system automatically selects the best backend:

| Platform | Auto-Selected Backend | GPU Support |
|----------|----------------------|-------------|
| **macOS** | Metal | ✅ Native Apple GPU |
| **Linux + NVIDIA GPU** | CUDA + Vulkan | ✅ CUDA Acceleration |
| **Linux + AMD GPU** | Vulkan | ✅ Vulkan Acceleration |
| **Linux (CPU)** | Vulkan | ✅ CPU Fallback |
| **Windows + NVIDIA** | CUDA + Vulkan | ✅ CUDA Acceleration |
| **Windows (CPU)** | Vulkan | ✅ CPU Fallback |

### Platform-Specific Commands

#### Apple Silicon Mac (ARM64)

```bash
# Docker (CPU-only, no Metal)
docker build --platform linux/arm64 -t mlc-llm-dev .
docker run -it --rm -e AUTO_CLONE=true mlc-llm-dev
bash /workspace/scripts/build-mlc.sh

# Native (Recommended - Metal GPU)
brew install cmake ninja git rust python@3.11
git clone --recursive https://github.com/salmanhabibkhan/mlc-llm-devops.git
cd mlc-llm && bash build-mlc.sh
```

#### Intel/AMD Linux (x86_64)

```bash
# Without GPU
docker build --platform linux/amd64 -t mlc-llm-dev .
docker run -it --rm -e AUTO_CLONE=true mlc-llm-dev
bash /workspace/scripts/build-mlc.sh

# With NVIDIA GPU
docker run -it --rm --gpus all -e AUTO_CLONE=true mlc-llm-dev
bash /workspace/scripts/build-mlc.sh --cuda
```

#### Windows (x86_64)

```bash
# In WSL2 or PowerShell with Docker
docker build -t mlc-llm-dev .
docker run -it --rm -e AUTO_CLONE=true mlc-llm-dev
bash /workspace/scripts/build-mlc.sh

# With NVIDIA GPU
docker run -it --rm --gpus all -e AUTO_CLONE=true mlc-llm-dev
bash /workspace/scripts/build-mlc.sh --cuda
```

---

## 🐳 Docker Image

### Image Details

- **Base**: Ubuntu 22.04 (multi-arch)
- **Size**: ~4.3 GB
- **Python**: 3.11
- **CMake**: 3.28.1
- **Includes**: GCC, Clang, Rust, Ninja, Git, CUDA tools (on x86_64)

### Building the Image

```bash
# For your native architecture
docker build -t mlc-llm-dev:local .

# For specific architecture
docker build --platform linux/amd64 -t mlc-llm-dev:local .
docker build --platform linux/arm64 -t mlc-llm-dev:local .

# Multi-architecture build
docker buildx create --use
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag ghcr.io/salmanhabibkhan/mlc-llm-dev:latest \
  --push \
  .
```

### Running the Container

#### Development Mode (Interactive)

```bash
# With auto-clone (easiest)
docker run -it --rm \
  -e AUTO_CLONE=true \
  -v mlc-cache:/root/.cache \
  mlc-llm-dev:local

# With source mounted
docker run -it --rm \
  -v /path/to/mlc-llm:/workspace \
  -v mlc-cache:/root/.cache \
  mlc-llm-dev:local

# With GPU support
docker run -it --rm --gpus all \
  -e AUTO_CLONE=true \
  mlc-llm-dev:local
```

#### Build Mode (CI/CD)

```bash
# Fully automated build
docker run --rm \
  -e BUILD_MODE=true \
  -v $(pwd)/dist:/workspace/dist \
  mlc-llm-dev:local
```

### Using Docker Compose

```bash
# Start development environment
docker-compose up -d mlc-dev

# Enter container
docker-compose exec mlc-dev bash

# Inside container
git clone --recursive https://github.com/salmanhabibkhan/mlc-llm-devops.git .
bash scripts/build-mlc.sh

# Stop when done
docker-compose down
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTO_CLONE` | `false` | Automatically clone MLC-LLM |
| `BUILD_MODE` | `false` | Run automated build |
| `ENABLE_CUDA` | `false` | Enable CUDA backend |
| `USE_METAL` | Auto-detect | Enable Metal (macOS) |
| `USE_VULKAN` | Auto-detect | Enable Vulkan |
| `USE_CUDA` | Auto-detect | Enable CUDA |

---

## ⚙️ CI/CD Pipeline

### Pipeline Overview

```
┌─────────────────────────────────────────────────────────┐
│  Stage 1: Build Docker Image                            │
│  • Multi-arch build (amd64)                             │
│  • Push to GHCR with tags                               │
│  • Security scan with Trivy                             │
│  Duration: ~8-12 min                                    │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  Stage 2: Run Tests (Matrix)                            │
│  • Unit tests with coverage                             │
│  • Integration tests                                    │
│  • Style checks (black, flake8)                         │
│  Duration: ~5-8 min per suite                           │
│  ⚠️  Failure blocks subsequent stages                   │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  Stage 3: Build Wheels (Matrix)                         │
│  • Linux x64 wheel                                      │
│  • Windows x64 wheel                                    │
│  Duration: ~15-25 min per platform                      │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼ (only on tags)
┌─────────────────────────────────────────────────────────┐
│  Stage 4: Create GitHub Release                         │
│  • Generate release notes                               │
│  • Attach wheels as assets                              │
│  Duration: ~2-3 min                                     │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  Stage 5: Validate Release                              │
│  • Install wheels on test systems                       │
│  • Run smoke tests                                      │
│  Duration: ~3-5 min                                     │
└─────────────────────────────────────────────────────────┘
```

### Workflow Triggers

| Event | Trigger | Behavior |
|-------|---------|----------|
| **Push to `master`** | Automatic | Full pipeline, no release |
| **Pull Request** | Automatic | Build + Test only | In progress Now
| **Tag `v*`** | Automatic | Full pipeline + GitHub Release |
| **Manual** | Via Actions UI | Configurable options |

### Pipeline Configuration

Location: `.github/workflows/ci-cd.yml`

Key features:
- **Test-Driven**: Tests must pass before building wheels
- **Matrix Builds**: Parallel execution for speed
- **Caching**: Docker layers, pip packages, CMake artifacts
- **Security**: Trivy scanning, minimal permissions
- **Artifacts**: Wheels stored for 90 days

### Setting Up CI/CD

1. **Fork/Copy this repository** to your GitHub

2. **Enable GitHub Actions**:
   - Go to repository Settings → Actions → General
   - Select "Allow all actions and reusable workflows"

3. **Configure Permissions**:
   - Settings → Actions → General → Workflow permissions
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

4. **Push code** to trigger first run:
```bash
git push origin master
```

5. **Create release** (optional):
```bash
git tag -a v0.1.0 -m "Initial release"
git push origin v0.1.0
```

6. **Monitor progress**:
   - Go to Actions tab in GitHub
   - Watch the pipeline execute
   - Download artifacts or release assets

### Pipeline Outputs

After successful pipeline:
- **Docker Image**: `ghcr.io/salmanhabibkhan/mlc-llm-dev:latest`
- **Linux Wheel**: `mlc_llm-*-linux_x86_64.whl`
- **Windows Wheel**: `mlc_llm-*-win_amd64.whl`
- **Test Reports**: Coverage and test results
- **GitHub Release**: (on tags) with all wheels attached

---

## 🔨 Building from Source

### Non-Interactive Build Script

The `scripts/build-mlc.sh` script provides fully automated builds:

**Features**:
- ✅ Platform auto-detection
- ✅ Backend auto-selection (Metal/CUDA/Vulkan)
- ✅ Non-interactive (zero questions)
- ✅ Parallel compilation
- ✅ Error handling and validation

**Usage**:

```bash
# Inside MLC-LLM source directory
bash scripts/build-mlc.sh

# With CUDA support
bash scripts/build-mlc.sh --cuda

# Force specific backends
export USE_METAL=ON   # macOS
export USE_CUDA=ON    # NVIDIA
export USE_VULKAN=ON  # Any platform
bash scripts/build-mlc.sh
```

### Manual Build Process

If you need to build manually:

```bash
# 1. Clone MLC-LLM
git clone --recursive https://github.com/salmanhabibkhan/mlc-llm-devops.git
cd mlc-llm

# 2. Create build directory
mkdir -p build && cd build

# 3. Configure CMake (non-interactive)
cmake .. -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_CUDA=OFF \
  -DUSE_VULKAN=ON \
  -DUSE_METAL=OFF

# 4. Build
cmake --build . --parallel $(nproc)

# 5. Install Python package
cd ../python
pip install -e .

# 6. Verify
python -c "import mlc_llm; print('Success!')"
```

### CMake Configuration Options

```cmake
# Backends
-DUSE_CUDA=ON/OFF      # NVIDIA CUDA
-DUSE_VULKAN=ON/OFF    # Vulkan (cross-platform)
-DUSE_METAL=ON/OFF     # Apple Metal (macOS only)
-DUSE_ROCM=ON/OFF      # AMD ROCm (Linux only)
-DUSE_OPENCL=ON/OFF    # OpenCL (legacy)

# Build type
-DCMAKE_BUILD_TYPE=Release        # Optimized
-DCMAKE_BUILD_TYPE=Debug          # With debug symbols
-DCMAKE_BUILD_TYPE=RelWithDebInfo # Release + debug info

# Performance
-DCMAKE_CXX_COMPILER_LAUNCHER=ccache  # Use ccache
```

---

## 📁 Project Structure

```
mlc-llm-devops/
│
├── Dockerfile                      # Multi-arch Docker image
├── docker-compose.yml             # Docker Compose config
├── docker-entrypoint.sh           # Smart container entrypoint
├── .dockerignore                  # Docker build exclusions
│
├── .github/
│   ├── workflows/
│   │   └── ci-cd.yml             # Main CI/CD pipeline
│   └── pull_request_template.md  # PR template
│
├── scripts/
│   ├── build-mlc.sh              # Non-interactive build script
│   └── setup-dev.sh              # Dev environment setup
│
├── cmake-config-presets/
│   └── config.cmake              # Non-interactive CMake config
│
├── tests/
│   ├── ccp/
│   │   └── conv_template_unittest.cc         # Unit tests
│   ├── python/integration/
│   │   └── test_model_compile.py         # Integration tests
│   ├── conftest.py               # Pytest fixtures
│   └── pytest.ini                # Test configuration
│
├── docs/
│   └── COMPLETE_GUIDE.md         # Comprehensive documentation
│
└── README.md                      # This file
```

### Key Files Explained

#### **Dockerfile**
- Multi-architecture support (x86_64, ARM64)
- Based on Ubuntu 22.04
- Includes all build dependencies
- ~4.3 GB final size
- Supports both dev and CI/CD modes

#### **docker-entrypoint.sh**
- Smart entrypoint script
- Detects development vs build mode
- Auto-clones MLC-LLM if requested
- Provides helpful instructions
- Handles platform detection

#### **scripts/build-mlc.sh**
- Fully automated build script
- Platform auto-detection
- Backend auto-selection
- Non-interactive (no questions)
- Comprehensive error handling

#### **.github/workflows/ci-cd.yml**
- 5-stage pipeline
- Matrix builds for multiple platforms
- Test-driven deployment
- Automated releases
- Security scanning

#### **docker-compose.yml**
- Local development setup
- Persistent volumes
- Multiple service definitions
- Easy container management

---

## 🔧 Configuration

### Backend Selection

Backends are automatically selected based on platform:

```bash
# Automatic (recommended)
bash scripts/build-mlc.sh

# Manual override
export USE_METAL=ON    # macOS only
export USE_CUDA=ON     # NVIDIA GPU
export USE_VULKAN=ON   # Any GPU
export USE_ROCM=ON     # AMD GPU (Linux)
export USE_OPENCL=ON   # Legacy

bash scripts/build-mlc.sh
```

### Docker Build Arguments

```bash
docker build \
  --build-arg PYTHON_VERSION=3.11 \
  --build-arg CMAKE_VERSION=3.28.1 \
  --platform linux/amd64 \
  -t mlc-llm-dev:custom .
```

### Pipeline Customization

Edit `.github/workflows/ci-cd.yml`:

```yaml
# Add more platforms
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    python-version: ['3.9', '3.10', '3.11']

# Change triggers
on:
  push:
    branches: [master, develop, staging]
    paths:
      - 'src/**'
      - 'CMakeLists.txt'

# Modify build flags
cmake .. -DUSE_CUDA=ON -DUSE_VULKAN=ON
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. QEMU Error: "Could not open '/lib64/ld-linux-x86-64.so.2'"

**Cause**: Architecture mismatch (running x86_64 image on ARM64)

**Solution**:
```bash
# Specify correct platform
docker build --platform linux/arm64 -t mlc-llm-dev .  # For Apple Silicon
docker build --platform linux/amd64 -t mlc-llm-dev .  # For Intel/AMD
```

#### 2. CMake Asks Interactive Questions

**Cause**: Using old `gen_cmake_config.py` script

**Solution**:
```bash
# Use non-interactive build script
bash scripts/build-mlc.sh

# Or configure CMake directly
cmake .. -GNinja -DUSE_VULKAN=ON -DUSE_CUDA=OFF
```

#### 3. Empty /workspace in Container

**Cause**: No source code mounted or cloned

**Solution**:
```bash
# Use auto-clone
docker run -it --rm -e AUTO_CLONE=true mlc-llm-dev

# Or mount source
docker run -it --rm -v /path/to/mlc-llm:/workspace mlc-llm-dev
```

#### 4. Build Fails with Memory Error

**Cause**: Insufficient RAM for parallel compilation

**Solution**:
```bash
# Limit parallel jobs
cmake --build . --parallel 2

# Or increase Docker memory limit
# Docker Desktop → Settings → Resources → Memory → 8GB+
```

#### 5. Permission Denied Writing Files

**Cause**: Container runs as root, host files owned by user

**Solution**:
```bash
# Run as current user
docker run --user $(id -u):$(id -g) -v $(pwd):/workspace mlc-llm-dev

# Or fix permissions afterward
sudo chown -R $USER:$USER ./build
```

#### 6. No GPU Support in Docker on macOS

**Cause**: Docker on macOS runs Linux in VM, can't access Metal

**Solution**:
```bash
# Use native build instead
brew install cmake ninja git rust python@3.11
git clone --recursive https://github.com/salmanhabibkhan/mlc-llm-devops.git
cd mlc-llm-devops && bash build-mlc.sh
```

### Getting Help

1. **Check documentation**: Read `docs/COMPLETE_GUIDE.md`
2. **Review logs**: 
   ```bash
   docker logs CONTAINER_ID
   gh run view RUN_ID --log-failed
   ```
3. **Enable verbose mode**:
   ```bash
   cmake --build . --verbose
   export VERBOSE=1
   ```
---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `pytest tests/`
5. Commit changes: `git commit -m 'Add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Development Setup

```bash
# Clone repository
git clone --recursive https://github.com/salmanhabibkhan/mlc-llm-devops.git
cd mlc-llm-devops

# Run setup script
bash scripts/setup-dev.sh

# Activate virtual environment
source venv/bin/activate

# Run tests
pytest tests/ -v

# Build Docker image
docker build -t mlc-llm-dev:test .
```
---

## 🙏 Acknowledgments

- [MLC-LLM Team](https://github.com/mlc-ai/mlc-llm) for the original project
- Community contributors and testers

---

## 📞 Support

- **Documentation**: See `docs/COMPLETE_GUIDE.md` for detailed information

---

## 📊 Status

- ✅ Multi-architecture Docker support
- ✅ Non-interactive build automation
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Cross-platform wheel building
- ✅ Automated testing and releases
- ✅ Comprehensive documentation

**Ready for production use!** 🚀

---

**Quick Links**:
- [Complete Documentation](docs/COMPLETE_GUIDE.md)
- [GitHub Actions Workflow](.github/workflows/ci-cd.yml)
- [Original Repo MLC-LLM Repository](https://github.com/mlc-ai/mlc-llm)