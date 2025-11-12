# Nanochat Local Setup Guide

This guide will help you set up and run nanochat locally on your machine.

## Table of Contents

- [Prerequisites](#prerequisites)
- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
  - [GPU Setup (Recommended for Training)](#gpu-setup-recommended-for-training)
  - [CPU/MPS Setup (For Development & Testing)](#cpumps-setup-for-development--testing)
- [Quick Start](#quick-start)
- [Running Components](#running-components)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Python**: 3.10 or higher (tested with 3.10, 3.11, 3.12)
- **uv**: Fast Python package installer and environment manager
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```
- **Rust & Cargo**: For building the custom BPE tokenizer
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

### System Check

Run these commands to verify your setup:

```bash
python3 --version    # Should be >= 3.10
uv --version         # Should be installed
cargo --version      # Should be installed
nvidia-smi           # Optional: check for GPU availability
```

## System Requirements

### Minimum (CPU Development)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free space
- **CPU**: Modern multi-core processor

### Recommended (GPU Training)
- **GPU**: NVIDIA GPU with CUDA support
  - For speedrun ($100 tier): 8x H100 GPUs or 8x A100 GPUs
  - For development: Single GPU with 16GB+ VRAM
- **RAM**: 32GB+ system RAM
- **Storage**: 100GB+ SSD for datasets and checkpoints

### Supported Platforms
- **Linux**: Full support (primary development platform)
- **macOS**: CPU and MPS (Apple Silicon) support
- **Windows**: Full native support (CPU and CUDA GPU)
  - Python code works natively on Windows
  - Shell scripts (.sh) need WSL or Git Bash, OR run Python commands directly
  - See [Windows-Specific Instructions](#windows-specific-instructions) below

## Installation Methods

### GPU Setup (Recommended for Training)

This setup is for training models on GPU-equipped machines.

1. **Clone the repository**:
   ```bash
   git clone https://github.com/karpathy/nanochat.git
   cd nanochat
   ```

2. **Create virtual environment and install dependencies**:
   ```bash
   # Create and activate virtual environment
   uv venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate

   # Install with GPU support
   pip install -e ".[gpu]"
   ```

3. **Build the Rust tokenizer**:
   ```bash
   cd rustbpe
   cargo build --release
   cd ..
   ```

4. **Verify installation**:
   ```bash
   python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
   python -c "import torch; print(f'CUDA devices: {torch.cuda.device_count()}')"
   ```

### CPU/MPS Setup (For Development & Testing)

This setup is for running nanochat on machines without NVIDIA GPUs (CPU or Mac with Apple Silicon).

1. **Clone the repository**:
   ```bash
   git clone https://github.com/karpathy/nanochat.git
   cd nanochat
   ```

2. **Create virtual environment and install dependencies**:
   ```bash
   # Create and activate virtual environment
   uv venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate

   # Install with CPU support
   pip install -e ".[cpu]"
   ```

3. **Build the Rust tokenizer**:
   ```bash
   cd rustbpe
   cargo build --release
   cd ..
   ```

4. **Verify installation**:
   ```bash
   python -c "import torch; print(f'PyTorch version: {torch.__version__}')"
   python -c "import nanochat; print('Nanochat imported successfully')"
   ```

### Alternative: Using uv sync

If you prefer to use `uv sync`:

```bash
# For CPU
uv sync --extra cpu

# For GPU (requires CUDA-capable GPU)
uv sync --extra gpu
```

### Windows-Specific Instructions

Nanochat works natively on Windows! Here's how to set it up:

#### Prerequisites for Windows

1. **Install Python 3.10+**:
   - Download from [python.org](https://www.python.org/downloads/)
   - During installation, check "Add Python to PATH"

2. **Install uv**:
   ```powershell
   # In PowerShell (as Administrator)
   irm https://astral.sh/uv/install.ps1 | iex
   ```

3. **Install Rust** (for tokenizer):
   - Download from [rustup.rs](https://rustup.rs/)
   - Run the installer and follow prompts

4. **Install Visual Studio Build Tools** (if not already installed):
   - Required for building Rust components
   - Download from [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022)
   - Select "C++ build tools" during installation

#### Installation on Windows

```powershell
# Clone the repository
git clone https://github.com/karpathy/nanochat.git
cd nanochat

# Create virtual environment
uv venv
.venv\Scripts\activate

# Install dependencies (CPU)
pip install -e ".[cpu]"

# OR for GPU (if you have NVIDIA GPU with CUDA)
pip install -e ".[gpu]"

# Build Rust tokenizer
cd rustbpe
cargo build --release
cd ..

# Verify installation
python -c "import torch; print(f'PyTorch version: {torch.__version__}')"
```

#### Running Training on Windows

Since the `.sh` shell scripts don't work directly on Windows, you have **three options**:

**Option 1: Run Python commands directly** (Recommended for Windows)

Instead of running `bash speedrun.sh`, you can run the Python commands directly:

```powershell
# Activate environment
.venv\Scripts\activate

# Example: Train base model
python -m scripts.base_train

# Example: Train with multiple GPUs (if available)
python -m torch.distributed.run --standalone --nproc_per_node=2 -m scripts.base_train

# Example: Start web interface
python -m scripts.chat_web
```

**Option 2: Use Git Bash** (comes with Git for Windows)

```bash
# In Git Bash
source .venv/Scripts/activate
bash speedrun.sh  # Or any other .sh script
```

**Option 3: Use WSL (Windows Subsystem for Linux)**

If you prefer the full Linux experience:

```bash
# In WSL Ubuntu
# Follow the Linux installation instructions
```

#### Windows-Specific Notes

1. **Path separators**: Python handles path separators automatically, so the code works fine
2. **File locking**: The project uses `filelock` instead of `fcntl`, so Windows is fully supported
3. **GPU support**: CUDA GPUs work on Windows - install CUDA toolkit from NVIDIA if needed
4. **PowerShell vs CMD**: PowerShell is recommended over CMD for better compatibility
5. **Long paths**: If you encounter path length issues, enable long path support in Windows:
   ```powershell
   # Run as Administrator
   New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
   ```

#### Creating a Windows Batch Script

You can create a `speedrun.bat` file to replicate the shell script functionality:

```batch
@echo off
REM Speedrun equivalent for Windows
call .venv\Scripts\activate.bat

REM Tokenizer training
python -m scripts.tok_train

REM Download data
python -m nanochat.dataset -n 100

REM Base training
python -m scripts.base_train

REM Evaluation
python -m scripts.base_eval

REM Midtraining
python -m scripts.mid_train

REM SFT
python -m scripts.chat_sft

REM Chat evaluation
python -m scripts.chat_eval

echo Training complete!
```

## Quick Start

### 1. Train a Small Model (CPU/Development)

For testing the pipeline on CPU or MPS (Apple Silicon), use the modified CPU training script:

```bash
# See dev/runcpu.sh for a minimal training example
bash dev/runcpu.sh
```

This will train a tiny model suitable for testing the pipeline without GPU resources.

### 2. Train the Speedrun Model (GPU Required)

For the $100 tier model (requires 8x H100 or similar):

```bash
# Option 1: Run directly
bash speedrun.sh

# Option 2: Run in screen session (recommended for long training)
screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
# Detach with Ctrl+A then D
# Reattach with: screen -r speedrun
```

The speedrun takes ~4 hours on 8x H100 GPUs.

### 3. Chat with Your Model

After training completes, start the web interface:

```bash
# Activate virtual environment
source .venv/bin/activate

# Start web server
python -m scripts.chat_web
```

Then open your browser to the URL shown (typically `http://localhost:8000`).

## Running Components

### Tokenizer Training

Train a custom BPE tokenizer:

```bash
python -m scripts.tok_train
```

### Base Model Training

Train the base language model:

```bash
# Single GPU
python -m scripts.base_train

# Multi-GPU (8 GPUs)
torchrun --standalone --nproc_per_node=8 -m scripts.base_train
```

### Midtraining

Continue training on domain-specific data:

```bash
torchrun --standalone --nproc_per_node=8 -m scripts.mid_train
```

### Supervised Fine-Tuning (SFT)

Fine-tune the model for chat:

```bash
python -m scripts.chat_sft
```

### Evaluation

Evaluate model performance:

```bash
# Base model CORE score
python -m scripts.base_eval

# Chat model evaluation
python -m scripts.chat_eval
```

### Inference

Talk to your model via CLI:

```bash
python -m scripts.chat_cli
```

Or via web interface:

```bash
python -m scripts.chat_web
```

## Troubleshooting

### Issue: Out of Memory (OOM)

**Solution**: Reduce `device_batch_size` in training scripts:

```bash
# Example: reduce from 32 to 16
torchrun --standalone --nproc_per_node=8 -m scripts.base_train -- --device_batch_size=16
```

The code automatically compensates by increasing gradient accumulation steps.

### Issue: uv sync fails with torch not found

**Solution**: Use pip install instead:

```bash
uv venv
source .venv/bin/activate
pip install -e ".[cpu]"  # or ".[gpu]"
```

### Issue: Rust tokenizer build fails

**Solution**: Ensure Rust is installed and up to date:

```bash
rustup update
cd rustbpe
cargo clean
cargo build --release
```

### Issue: ImportError: No module named 'rustbpe'

**Solution**: The Rust extension needs to be built:

```bash
# Install in editable mode with maturin
pip install -e ".[cpu]"

# Or build manually
cd rustbpe
cargo build --release
cd ..
python -c "import rustbpe; print('Success')"
```

### Issue: Training is too slow on CPU

**Solution**: This is expected. For development on CPU:

1. Use smaller models (reduce `--depth`)
2. Use fewer training iterations
3. Use smaller batch sizes
4. Refer to `dev/runcpu.sh` for appropriate CPU settings

### Issue: CUDA out of memory during training

**Solutions**:
1. Reduce `device_batch_size` (e.g., from 32 to 16, 8, or 4)
2. Use smaller model (`--depth=20` instead of `--depth=26`)
3. Use gradient checkpointing (if available in config)
4. Train on fewer GPUs (slower but uses less memory per GPU)

### Issue: Cannot access web UI

**Solutions**:
1. Check the port is correct (default: 8000)
2. For remote servers, use the public IP:
   ```
   http://<server-ip>:8000
   ```
3. Ensure firewall allows incoming connections on port 8000
4. For cloud instances (e.g., Lambda), check security groups/firewall rules

## Next Steps

After successful setup:

1. Read [BEST_PRACTICES.md](BEST_PRACTICES.md) for development guidelines
2. Explore the codebase structure in the main [README.md](README.md)
3. Join discussions at https://github.com/karpathy/nanochat/discussions
4. Try customizing your model (see discussions for guides)

## Getting Help

- **Issues**: https://github.com/karpathy/nanochat/issues
- **Discussions**: https://github.com/karpathy/nanochat/discussions
- **Documentation**: See README.md and code comments

## Useful Commands

```bash
# Check GPU utilization
nvidia-smi -l 1

# Monitor training progress
tail -f speedrun.log

# List running screen sessions
screen -ls

# Package repository for LLM analysis
files-to-prompt . -e py -e md -e rs -e html -e toml -e sh --ignore "*target*" --cxml > packaged.txt

# Run tests
python -m pytest tests/ -v

# Run specific test
python -m pytest tests/test_rustbpe.py -v -s
```
