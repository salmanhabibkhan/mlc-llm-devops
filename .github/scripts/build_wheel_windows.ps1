$ErrorActionPreference = "Stop"

mkdir build
cd build

cmake .. -DCMAKE_BUILD_TYPE=Release -C ../templates/wheel-config.cmake
cmake --build . --config Release

pip install build
python -m build
