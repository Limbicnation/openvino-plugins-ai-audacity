#!/bin/bash
set -e

# Destination
DEST="/usr/local/lib/openvino-models"
TEMP_DIR="$HOME/audacity-openvino/temp_models"

mkdir -p $TEMP_DIR
cd $TEMP_DIR

echo "Fixing model installation..."

# 1. Whisper Models (Move from subfolder if exists, or re-download)
if [ -d "$HOME/audacity-openvino/openvino-models/whisper.cpp-openvino-models" ]; then
    echo "Processing existing Whisper download..."
    # The previous script cloned the repo but didn't unzip the archives inside it
    cd "$HOME/audacity-openvino/openvino-models/whisper.cpp-openvino-models"
    # Try to unzip if zip files exist
    if ls *.zip 1> /dev/null 2>&1; then
        sudo unzip -o "*.zip" -d "$DEST"
    fi
    cd $TEMP_DIR
fi

# 2. Demucs (Music Separation) - Direct Download
echo "Downloading Demucs (Music Separation)..."
git clone --no-checkout https://huggingface.co/Intel/demucs-openvino
cd demucs-openvino
git checkout 97fc578fb57650045d40b00bc84c7d156be77547
sudo cp htdemucs_v4.bin "$DEST"
sudo cp htdemucs_v4.xml "$DEST"
cd ..
rm -rf demucs-openvino

# 3. Noise Suppression
echo "Downloading Noise Suppression..."
git clone --no-checkout https://huggingface.co/Intel/deepfilternet-openvino
cd deepfilternet-openvino
git checkout 995706bda3da69da0825074ba7dbc8a78067e980
sudo unzip -o deepfilternet2.zip -d "$DEST"
sudo unzip -o deepfilternet3.zip -d "$DEST"
cd ..
rm -rf deepfilternet-openvino

# Open Model Zoo Noise Suppression
sudo wget -q --show-progress -O "$DEST/noise-suppression-denseunet-ll-0001.xml" https://storage.openvinotoolkit.org/repositories/open_model_zoo/2023.0/models_bin/1/noise-suppression-denseunet-ll-0001/FP16/noise-suppression-denseunet-ll-0001.xml
sudo wget -q --show-progress -O "$DEST/noise-suppression-denseunet-ll-0001.bin" https://storage.openvinotoolkit.org/repositories/open_model_zoo/2023.0/models_bin/1/noise-suppression-denseunet-ll-0001/FP16/noise-suppression-denseunet-ll-0001.bin

# 4. Super Resolution
echo "Downloading Super Resolution..."
git clone --no-checkout https://huggingface.co/Intel/versatile_audio_super_resolution_openvino
cd versatile_audio_super_resolution_openvino
git checkout 9a97d7f128b22aea72e92862a3eccc310f88ac26
sudo mkdir -p "$DEST/audiosr"
sudo unzip -o versatile_audio_sr_base_openvino_models.zip -d "$DEST/audiosr"
sudo unzip -o versatile_audio_sr_ddpm_basic_openvino_models.zip -d "$DEST/audiosr"
sudo unzip -o versatile_audio_sr_ddpm_speech_openvino_models.zip -d "$DEST/audiosr"
cd ..
rm -rf versatile_audio_super_resolution_openvino

echo "Done! Models installed to $DEST"
ls -F $DEST
