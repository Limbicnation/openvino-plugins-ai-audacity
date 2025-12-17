#!/bin/bash
set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

ROOT_DIR=$HOME/audacity-openvino
mkdir -p $ROOT_DIR
cd $ROOT_DIR

echo "Starting component setup in $ROOT_DIR..."

# Install OpenCL (required for GPU optimization)
echo "Installing OpenCL development packages..."
sudo apt install -y ocl-icd-opencl-dev

# 1. OpenVINO
echo "Downloading OpenVINO..."
if [ ! -d "openvino_toolkit" ]; then
    mkdir -p openvino_toolkit
    cd openvino_toolkit
    # Using 22.04 package as per guide, usually works on 24.04
    wget -q --show-progress https://storage.openvinotoolkit.org/repositories/openvino/packages/2024.6/linux/l_openvino_toolkit_ubuntu22_2024.6.0.17404.4c0f47d2335_x86_64.tgz
    tar xf l_openvino_toolkit_ubuntu22_2024.6.0.17404.4c0f47d2335_x86_64.tgz
    
    # Install dependencies
    echo "Installing OpenVINO dependencies..."
    cd l_openvino_toolkit_ubuntu22_2024.6.0.17404.4c0f47d2335_x86_64/install_dependencies/
    sudo -E ./install_openvino_dependencies.sh
    cd ../../..
else
    echo "OpenVINO directory exists, skipping download."
fi

# 2. OpenVINO Tokenizers
echo "Downloading OpenVINO Tokenizers..."
if [ ! -d "openvino_tokenizers" ]; then
    mkdir -p openvino_tokenizers
    cd openvino_tokenizers
    wget -q --show-progress https://storage.openvinotoolkit.org/repositories/openvino_tokenizers/packages/2024.6.0.0/openvino_tokenizers_ubuntu22_2024.6.0.0_x86_64.tar.gz
    tar xzf openvino_tokenizers_ubuntu22_2024.6.0.0_x86_64.tar.gz
    
    # Copy libs to OpenVINO runtime
    OV_DIR=$(find $ROOT_DIR/openvino_toolkit -name "l_openvino_toolkit_*" -type d | head -n 1)
    echo "Copying tokenizer libs to $OV_DIR/runtime/lib/intel64/"
    cp -r runtime/lib/intel64/* "$OV_DIR/runtime/lib/intel64/"
    cd ..
else
    echo "OpenVINO Tokenizers directory exists, skipping."
fi

# 3. Libtorch
echo "Downloading Libtorch..."
if [ ! -d "libtorch" ]; then
    wget -q --show-progress https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-2.4.1%2Bcpu.zip
    unzip -q libtorch-cxx11-abi-shared-with-deps-2.4.1+cpu.zip
    # This creates a 'libtorch' directory directly
else
    echo "Libtorch directory exists, skipping."
fi

# 4. Whisper.cpp
echo "Building Whisper.cpp..."
if [ ! -d "whisper-build" ]; then
    if [ ! -d "whisper.cpp" ]; then
        git clone https://github.com/ggerganov/whisper.cpp
        cd whisper.cpp
        git checkout v1.5.4
        cd ..
    fi
    
    mkdir -p whisper-build
    cd whisper-build
    
    # Setup ENV for build
    OV_DIR=$(find $ROOT_DIR/openvino_toolkit -name "l_openvino_toolkit_*" -type d | head -n 1)
    source "$OV_DIR/setupvars.sh"
    
    cmake ../whisper.cpp/ -DWHISPER_OPENVINO=ON
    make -j$(nproc)
    cmake --install . --config Release --prefix ./installed
    cd ..
else
    echo "Whisper build directory exists, skipping."
fi

echo "Component setup complete."
