# OpenVINO™ AI Plugins for Audacity

## Project Overview
This project provides a set of AI-enabled effects, generators, and analyzers for [Audacity®](https://www.audacityteam.org/). These features run 100% locally on the user's PC using [OpenVINO™](https://github.com/openvinotoolkit/openvino) to accelerate AI models on CPU, GPU, and NPU.

**Key Features:**
*   **Music Separation:** Separate mono/stereo tracks into individual stems (Drums, Bass, Vocals, Other).
*   **Noise Suppression:** Remove background noise using DeepFilterNet and other models.
*   **Music Generation:** Generate music snippets or continuations using MusicGen LLM.
*   **Whisper Transcription:** Transcribe or translate spoken audio using `whisper.cpp` with OpenVINO backend.
*   **Super Resolution:** Upscale and enrich audio clarity.

## Building and Running (Linux)

The build process involves preparing dependencies, building sub-components (`whisper.cpp`), modifying the Audacity source tree, and then building Audacity.

### Prerequisites
*   **System:** Linux (Instructions optimized for Ubuntu 22.04)
*   **Dependencies:**
    *   Build Essentials (GCC, CMake)
    *   OpenVINO Toolkit (2024.6 recommended)
    *   OpenVINO Tokenizers Extension
    *   Libtorch (C++ PyTorch distribution)
    *   OpenCL headers (`ocl-icd-opencl-dev`)
    *   Audacity build deps: `python3-pip`, `conan`, `libgtk2.0-dev`, `libasound2-dev`, `libjack-jackd2-dev`, `uuid-dev`

### Build Steps

1.  **Setup Environment Variables:**
    Ensure `LIBTORCH_ROOTDIR` and OpenVINO environment variables are set (source `setupvars.sh`).

2.  **Build `whisper.cpp`:**
    *   Clone `whisper.cpp` (tag `v1.5.4`).
    *   Build with OpenVINO support: `cmake -DWHISPER_OPENVINO=ON ...`
    *   Install to a local directory.
    *   Set `WHISPERCPP_ROOTDIR` to the install location.

3.  **Prepare Audacity Source:**
    *   Clone Audacity (e.g., `release-3.7.1`).
    *   Copy the `mod-openvino` directory from this repository into `audacity/modules/`.
    *   Edit `audacity/modules/CMakeLists.txt` to add: `add_subdirectory(mod-openvino)`.

4.  **Build Audacity:**
    ```bash
    mkdir audacity-build
    cd audacity-build
    cmake -G "Unix Makefiles" ../audacity -DCMAKE_BUILD_TYPE=Release
    make -j`nproc`
    ```

5.  **Install Models:**
    Models must be downloaded and placed in `/usr/local/lib/openvino-models/`. Scripts/commands to download models for MusicGen, Whisper, Demucs, DeepFilterNet, and AudioSR are provided in `doc/build_doc/linux/README.md`.

### Running
1.  Run the built binary: `./Release/bin/audacity`
2.  Go to **Edit -> Preferences -> Modules**.
3.  Set `mod-openvino` to **Enabled**.
4.  Restart Audacity.

## Development Conventions

*   **License:** GPL v3.
*   **Contribution:** Pull requests are welcome.
*   **Sign-off:** All commits **must** be signed off to certify the Developer Certificate of Origin (DCO). Use `git commit -s`.
*   **Style:** Follow the existing coding style in the `mod-openvino` directory.

## Key Directories
*   `mod-openvino/`: Source code for the OpenVINO Audacity module.
*   `doc/`: Documentation for features and build instructions.
*   `tools/`: Helper scripts (mostly Windows-focused, but contains some patches).
