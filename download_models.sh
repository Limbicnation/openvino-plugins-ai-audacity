#!/bin/bash
set -e

# Directory
MODELS_DIR=$HOME/audacity-openvino/openvino-models
mkdir -p $MODELS_DIR
cd $MODELS_DIR

echo "Checking for git-lfs..."
if ! command -v git-lfs &> /dev/null; then
    echo "Installing git-lfs..."
    sudo apt-get install -y git-lfs
    git lfs install
fi

# MusicGen
echo "Downloading MusicGen models..."
mkdir -p musicgen
if [ ! -d "musicgen/musicgen_small_enc_dec_tok_openvino_models" ]; then
    git clone --no-checkout https://huggingface.co/Intel/musicgen-static-openvino
    cd musicgen-static-openvino
    git checkout b2ad8083f3924ed704814b68c5df9cbbf2ad2aae
    cd ..
    unzip -o musicgen-static-openvino/musicgen_small_enc_dec_tok_openvino_models.zip -d musicgen
    unzip -o musicgen-static-openvino/musicgen_small_mono_openvino_models.zip -d musicgen
    unzip -o musicgen-static-openvino/musicgen_small_stereo_openvino_models.zip -d musicgen
    rm -rf musicgen-static-openvino
else
    echo "MusicGen models appear to be present."
fi

# Whisper - Use direct download to avoid LFS timeout
echo "Downloading Whisper models..."
if [ ! -f "ggml-base.bin" ]; then
    echo "Downloading ggml-base models..."
    wget -q --show-progress https://huggingface.co/Intel/whisper.cpp-openvino-models/resolve/main/ggml-base-models.zip
    unzip -o ggml-base-models.zip -d .
    rm -f ggml-base-models.zip

    echo "Downloading ggml-small models..."
    wget -q --show-progress https://huggingface.co/Intel/whisper.cpp-openvino-models/resolve/main/ggml-small-models.zip
    unzip -o ggml-small-models.zip -d .
    rm -f ggml-small-models.zip
else
    echo "Whisper models appear to be present."
fi

# Demucs (Music Separation)
echo "Downloading Demucs models..."
if [ ! -f "htdemucs_v4.bin" ]; then
    git clone --no-checkout https://huggingface.co/Intel/demucs-openvino
    cd demucs-openvino
    git checkout 97fc578fb57650045d40b00bc84c7d156be77547
    cd ..
    cp demucs-openvino/htdemucs_v4.bin .
    cp demucs-openvino/htdemucs_v4.xml .
    rm -rf demucs-openvino
else
    echo "Demucs models appear to be present."
fi

# Noise Suppression
echo "Downloading Noise Suppression models..."
if [ ! -d "deepfilter" ]; then # approximate check
    git clone --no-checkout https://huggingface.co/Intel/deepfilternet-openvino
    cd deepfilternet-openvino
    git checkout 995706bda3da69da0825074ba7dbc8a78067e980
    cd ..
    unzip -o deepfilternet-openvino/deepfilternet2.zip -d .
    unzip -o deepfilternet-openvino/deepfilternet3.zip -d .
    rm -rf deepfilternet-openvino

    wget -q --show-progress -O noise-suppression-denseunet-ll-0001.xml https://storage.openvinotoolkit.org/repositories/open_model_zoo/2023.0/models_bin/1/noise-suppression-denseunet-ll-0001/FP16/noise-suppression-denseunet-ll-0001.xml
    wget -q --show-progress -O noise-suppression-denseunet-ll-0001.bin https://storage.openvinotoolkit.org/repositories/open_model_zoo/2023.0/models_bin/1/noise-suppression-denseunet-ll-0001/FP16/noise-suppression-denseunet-ll-0001.bin
fi

# Super Resolution
echo "Downloading Super Resolution models..."
mkdir -p audiosr
if [ ! -d "audiosr/versatile_audio_super_resolution_openvino" ]; then
    git clone --no-checkout https://huggingface.co/Intel/versatile_audio_super_resolution_openvino
    cd versatile_audio_super_resolution_openvino
    git checkout 9a97d7f128b22aea72e92862a3eccc310f88ac26
    cd ..
    unzip -o versatile_audio_super_resolution_openvino/versatile_audio_sr_base_openvino_models.zip -d audiosr
    unzip -o versatile_audio_super_resolution_openvino/versatile_audio_sr_ddpm_basic_openvino_models.zip -d audiosr
    unzip -o versatile_audio_super_resolution_openvino/versatile_audio_sr_ddpm_speech_openvino_models.zip -d audiosr
    rm -rf versatile_audio_super_resolution_openvino
fi

# Install to /usr/local/lib - EXPLICIT FILES ONLY (security: avoid copying unintended files)
echo "Installing models to /usr/local/lib/openvino-models..."
sudo mkdir -p /usr/local/lib/openvino-models/{musicgen,audiosr,deepfilternet2,deepfilternet3}

# Copy specific model directories
[ -d musicgen ] && sudo cp -r musicgen/* /usr/local/lib/openvino-models/musicgen/
[ -d audiosr ] && sudo cp -r audiosr/* /usr/local/lib/openvino-models/audiosr/
[ -d deepfilternet2 ] && sudo cp -r deepfilternet2/* /usr/local/lib/openvino-models/deepfilternet2/
[ -d deepfilternet3 ] && sudo cp -r deepfilternet3/* /usr/local/lib/openvino-models/deepfilternet3/

# Copy individual model files
sudo cp -v htdemucs_v4.* /usr/local/lib/openvino-models/ 2>/dev/null || true
sudo cp -v ggml-*.bin ggml-*.xml /usr/local/lib/openvino-models/ 2>/dev/null || true
sudo cp -v noise-suppression-*.xml noise-suppression-*.bin /usr/local/lib/openvino-models/ 2>/dev/null || true

# Record installation metadata
cat <<EOF | sudo tee /usr/local/lib/openvino-models/VERSION.txt
Installation Date: $(date -I)
OpenVINO: 2024.6.0
Script Version: 1.0

Models:
- MusicGen: Intel/musicgen-static-openvino @ b2ad8083f3924ed704814b68c5df9cbbf2ad2aae
- Whisper: Intel/whisper.cpp-openvino-models (direct download)
- Demucs: Intel/demucs-openvino @ 97fc578fb57650045d40b00bc84c7d156be77547
- DeepFilterNet: Intel/deepfilternet-openvino @ 995706bda3da69da0825074ba7dbc8a78067e980
- AudioSR: Intel/versatile_audio_super_resolution_openvino @ 9a97d7f128b22aea72e92862a3eccc310f88ac26
EOF

echo "Model installation complete."
