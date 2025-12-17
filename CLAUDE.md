# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenVINO AI Plugins for Audacity - a set of AI-enabled audio effects, generators, and analyzers that run 100% locally using Intel's OpenVINO toolkit. The module (`mod-openvino`) integrates into Audacity as a dynamically loaded plugin.

**Features:**

- Music Separation (Demucs v4) - separate tracks into Drums, Bass, Vocals, Other
- Noise Suppression (DeepFilterNet, DenseUNet)
- Music Generation (MusicGen LLM)
- Whisper Transcription (whisper.cpp with OpenVINO backend)
- Super Resolution (AudioSR)

## Available AI Features

### Effects (Effect Menu)

#### 🎵 OpenVINO Music Separation

Separates a mono/stereo track into individual stems using Demucs v4.

- **Separation Modes:**
  - **2-Stem** → Instrumental + Vocals
  - **4-Stem** → Drums + Bass + Other Instruments + Vocals
- **Options:** Device selection, Shifts (higher = better quality but slower)

#### 🧹 OpenVINO Noise Suppression

Removes background noise from spoken audio.

- **Models:**
  - `deepfilternet2` (recommended)
  - `deepfilternet3` (recommended)
  - `denseunet` (legacy)
- **Devices:** CPU, GPU, NPU

#### ✨ OpenVINO Super Resolution

Upscales audio to 24kHz bandwidth / 48kHz sample rate using AudioSR diffusion.

- **Models:**
  - `Basic (General)` - music, environmental sounds
  - `Speech` - isolated speech
- **Options:** Chunk size, Steps, Guidance Scale, Seed

---

### Generators (Generate Menu)

#### 🎶 OpenVINO Music Generation

Text-to-music generation using MusicGen LLM. Also supports audio continuation.

- **Models:**
  - `musicgen-small` (mono, 32kHz)
  - `musicgen-stereo-small` (stereo, 32kHz)
  - fp16 (higher quality) or int8 (faster, less memory)
- **Features:**
  - Text prompt → music generation
  - Audio continuation (extend existing audio)
- **Options:** Duration, Seed, Guidance Scale, TopK, Context Length

---

### Analyzers (Analyze Menu)

#### 🎤 OpenVINO Whisper Transcription

Speech-to-text transcription/translation using whisper.cpp with OpenVINO backend.

- **Models:** base, small, small.en-tdrz (diarization), medium, large-v1/v2/v3
- **Modes:**
  - `transcribe` - output in source language
  - `translate` - output in English
- **Options:** Source language (auto-detect or explicit), Initial prompt, Max segment length, Beam size

---

### Device Support

All features support OpenVINO device selection:

- **CPU** - Always available
- **GPU** - Intel/discrete GPUs via OpenCL
- **NPU** - Intel Neural Processing Units (where available)

### Models Location

Models must be installed in `/usr/local/lib/openvino-models/`

## Build Commands (Linux/Ubuntu 22.04)

### Prerequisites Setup

```bash
# Install system dependencies
sudo apt install build-essential cmake git python3-pip ocl-icd-opencl-dev git-lfs
sudo apt install libgtk2.0-dev libasound2-dev libjack-jackd2-dev uuid-dev
sudo pip3 install conan

# OpenVINO (2024.6)
tar xvf l_openvino_toolkit_ubuntu22_2024.6.0.17404.4c0f47d2335_x86_64.tgz
source l_openvino_toolkit_ubuntu22_*/setupvars.sh

# Libtorch
export LIBTORCH_ROOTDIR=/path/to/libtorch
```

### Build whisper.cpp (dependency)

```bash
git clone https://github.com/ggerganov/whisper.cpp && cd whisper.cpp
git checkout v1.5.4
mkdir ../whisper-build && cd ../whisper-build
cmake ../whisper.cpp -DWHISPER_OPENVINO=ON
make -j$(nproc)
cmake --install . --config Release --prefix ./installed
export WHISPERCPP_ROOTDIR=$(pwd)/installed
export LD_LIBRARY_PATH=${WHISPERCPP_ROOTDIR}/lib:$LD_LIBRARY_PATH
```

### Build Audacity with mod-openvino

```bash
# Clone Audacity
git clone https://github.com/audacity/audacity.git
cd audacity && git checkout release-3.7.1 && cd ..

# Copy mod-openvino into Audacity source tree
cp -r openvino-plugins-ai-audacity/mod-openvino audacity/modules/

# Edit audacity/modules/CMakeLists.txt - add this line:
# add_subdirectory(mod-openvino)

# Build
mkdir audacity-build && cd audacity-build
cmake -G "Unix Makefiles" ../audacity -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### Running

```bash
./Release/bin/audacity
# Go to Edit -> Preferences -> Modules -> Set mod-openvino to "Enabled" -> Restart
```

## Architecture

### Module Structure (`mod-openvino/`)

- `OpenVINO.cpp` - Module entry point, defines version check and dispatch
- `OV*.cpp/h` - Audacity effect implementations inheriting from `StatefulEffect`
  - `OVMusicSeparation` - Demucs-based stem separation
  - `OVNoiseSuppression` - Multiple noise suppression models
  - `OVMusicGenerationLLM` - MusicGen text-to-music
  - `OVWhisperTranscription` - Speech-to-text via whisper.cpp
  - `OVAudioSR` - Audio super resolution
- `htdemucs.cpp/h` - HTDemucs model wrapper for music separation

### AI Pipeline Implementations

- `musicgen/` - MusicGen LLM pipeline (ported from HuggingFace transformers)
- `noise_suppression/deepfilternet/` - DeepFilterNet2/3 pipeline
- `audio_sr/` - AudioSR latent diffusion pipeline

### Dependencies (via CMake)

- OpenVINO Runtime - AI model inference
- Libtorch - Tensor operations for ported PyTorch pipelines
- whisper.cpp - Transcription backend
- OpenCL - GPU memory interoperability

### Models Location

Models must be placed in `/usr/local/lib/openvino-models/`. See `doc/build_doc/linux/README.md` for download commands.

## Development Conventions

- **License:** GPL v3
- **Commits:** Must be signed off (`git commit -s`) for DCO compliance
- **Code style:** Follow existing patterns in `mod-openvino/`
- **Effects:** Inherit from `StatefulEffect` and `StatefulEffectUIServices`
