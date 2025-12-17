#!/bin/bash
set -e

# Directories
WORKSPACE=$HOME/audacity-openvino
PLUGIN_SRC_DIR=$(pwd) # Assumes running from project root
AUDACITY_SRC_DIR=$WORKSPACE/audacity
BUILD_DIR=$WORKSPACE/audacity-build

echo "Starting Audacity build..."
echo "Workspace: $WORKSPACE"
echo "Plugin Source: $PLUGIN_SRC_DIR"

# 1. Clone Audacity
if [ ! -d "$AUDACITY_SRC_DIR" ]; then
    echo "Cloning Audacity..."
    cd $WORKSPACE
    git clone https://github.com/audacity/audacity.git
    cd audacity
    git checkout release-3.7.1
    cd ..
else
    echo "Audacity source exists, skipping clone."
fi

# 2. Copy Plugin Module
echo "Copying mod-openvino to Audacity modules..."
if [ -d "$PLUGIN_SRC_DIR/mod-openvino" ]; then
    cp -r "$PLUGIN_SRC_DIR/mod-openvino" "$AUDACITY_SRC_DIR/modules/"
else
    echo "Error: mod-openvino not found in $PLUGIN_SRC_DIR"
    exit 1
fi

# 3. Patch CMakeLists.txt
CMAKE_FILE="$AUDACITY_SRC_DIR/modules/CMakeLists.txt"
if ! grep -q "mod-openvino" "$CMAKE_FILE"; then
    echo "Patching modules/CMakeLists.txt..."
    # Insert add_subdirectory(mod-openvino) after the foreach loop
    sed -i '/endforeach()/a add_subdirectory(mod-openvino)' "$CMAKE_FILE"
else
    echo "CMakeLists.txt already patched."
fi

# 4. Build Environment Setup
# Find OpenVINO setupvars
OV_SETUP=$(find $WORKSPACE/openvino_toolkit -name "setupvars.sh" | head -n 1)
if [ -z "$OV_SETUP" ]; then
    echo "Error: OpenVINO setupvars.sh not found!"
    exit 1
fi
source "$OV_SETUP"

# Corrected Libtorch path
export LIBTORCH_ROOTDIR=$WORKSPACE/libtorch
export WHISPERCPP_ROOTDIR=$WORKSPACE/whisper-build/installed
export LD_LIBRARY_PATH=$WHISPERCPP_ROOTDIR/lib:$LD_LIBRARY_PATH

echo "Environment:"
echo "  LIBTORCH_ROOTDIR=$LIBTORCH_ROOTDIR"
echo "  WHISPERCPP_ROOTDIR=$WHISPERCPP_ROOTDIR"

# 5. CMake & Make
mkdir -p $BUILD_DIR
cd $BUILD_DIR

echo "Running CMake..."
cmake -G "Unix Makefiles" "$AUDACITY_SRC_DIR" -DCMAKE_BUILD_TYPE=Release

echo "Building Audacity (this may take a while)..."
make -j$(nproc)

echo "Build complete!"
echo "Run Audacity with: $BUILD_DIR/Release/bin/audacity"