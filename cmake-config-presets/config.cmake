# -------------------------------------------------------------
# MLC-LLM CMake Configuration Presets
# Central configuration for all platforms and backends
# -------------------------------------------------------------

# ------------------------------
# Backend configuration defaults
# These can still be overridden by environment variables or CLI:
#   cmake -DUSE_CUDA=ON ..
# ------------------------------
set(USE_CUDA    OFF   CACHE BOOL "Build with CUDA support")
set(USE_ROCM    OFF   CACHE BOOL "Build with ROCm support")
set(USE_VULKAN  ON    CACHE BOOL "Build with Vulkan support")
set(USE_METAL   OFF   CACHE BOOL "Build with Metal support (macOS)")
set(USE_OPENCL  OFF   CACHE BOOL "Build with OpenCL support")

# ------------------------------
# Build configuration
# ------------------------------
set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type")

set(BUILD_CPP_TEST                OFF CACHE BOOL   "Build C++ tests")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON  CACHE BOOL   "Export compile_commands.json")
set(HIDE_PRIVATE_SYMBOLS          ON  CACHE BOOL   "Hide private symbols")
set(USE_LIBBACKTRACE              AUTO CACHE STRING "Use libbacktrace (AUTO/ON/OFF)")

# ------------------------------
# Install prefix
# ------------------------------
set(CMAKE_INSTALL_PREFIX "/usr/local" CACHE PATH "Installation prefix")

# ------------------------------
# Compiler flags
# Add -fPIC for shared library support
# ------------------------------
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC" CACHE STRING "C++ flags")
set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   -fPIC" CACHE STRING "C flags")

# ------------------------------
# Use ccache if available
# ------------------------------
find_program(CCACHE_PROGRAM ccache)
if (CCACHE_PROGRAM)
    message(STATUS "Using ccache: ${CCACHE_PROGRAM}")
    set(CMAKE_C_COMPILER_LAUNCHER   "${CCACHE_PROGRAM}" CACHE STRING "" FORCE)
    set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}" CACHE STRING "" FORCE)
endif()

# ------------------------------
# Platform-specific rules
# ------------------------------
if (APPLE)
    message(STATUS "Detected macOS — enabling Metal backend")

    # Metal only
    set(USE_METAL   ON  CACHE BOOL "Build with Metal support (macOS)" FORCE)
    set(USE_VULKAN  OFF CACHE BOOL "Disable Vulkan on macOS"         FORCE)

    # Metal builds cannot use CUDA or ROCm
    set(USE_CUDA OFF CACHE BOOL "Disable CUDA on macOS" FORCE)
    set(USE_ROCM OFF CACHE BOOL "Disable ROCm on macOS" FORCE)
endif()

# ------------------------------
# Auto-parallel build
# ------------------------------
include(ProcessorCount)
ProcessorCount(NUM_CPUS)

if (NUM_CPUS GREATER 0)
    set(CMAKE_BUILD_PARALLEL_LEVEL ${NUM_CPUS} CACHE STRING "Parallel build level")
    message(STATUS "Parallel build enabled: ${NUM_CPUS} jobs")
endif()
