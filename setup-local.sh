#!/bin/bash

# Nanochat Local Setup Script
# This script helps you set up nanochat for local development

set -e  # Exit on error

echo "========================================="
echo "Nanochat Local Setup"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check Python
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    print_status "Python $PYTHON_VERSION found"

    # Check if version is >= 3.10
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

    if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 10 ]); then
        print_error "Python 3.10 or higher is required"
        exit 1
    fi
else
    print_error "Python 3 is not installed"
    exit 1
fi

# Check uv
if command_exists uv; then
    UV_VERSION=$(uv --version | awk '{print $2}')
    print_status "uv $UV_VERSION found"
else
    print_warning "uv is not installed"
    echo "Would you like to install uv? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        print_status "uv installed successfully"
        export PATH="$HOME/.local/bin:$PATH"
    else
        print_error "uv is required. Exiting."
        exit 1
    fi
fi

# Check Cargo/Rust
if command_exists cargo; then
    CARGO_VERSION=$(cargo --version | awk '{print $2}')
    print_status "Cargo $CARGO_VERSION found"
else
    print_warning "Cargo/Rust is not installed"
    echo "Would you like to install Rust? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        print_status "Rust installed successfully"
    else
        print_warning "Rust is optional but recommended for the custom BPE tokenizer"
    fi
fi

# Check for GPU
echo ""
echo "Checking for GPU..."
if command_exists nvidia-smi; then
    GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
    print_status "NVIDIA GPU detected: $GPU_INFO"
    INSTALL_GPU=true
else
    print_warning "No NVIDIA GPU detected. Will use CPU mode."
    INSTALL_GPU=false
fi

# Ask user for installation mode
echo ""
echo "Installation mode:"
if [ "$INSTALL_GPU" = true ]; then
    echo "1) GPU mode (recommended - you have a GPU)"
    echo "2) CPU mode (slower, for development/testing)"
    read -p "Choose mode (1 or 2): " MODE_CHOICE

    if [ "$MODE_CHOICE" = "1" ]; then
        EXTRA="gpu"
        print_status "Installing in GPU mode"
    else
        EXTRA="cpu"
        print_status "Installing in CPU mode"
    fi
else
    EXTRA="cpu"
    print_status "Installing in CPU mode"
fi

# Create virtual environment
echo ""
echo "Creating virtual environment..."
if [ -d ".venv" ]; then
    print_warning "Virtual environment already exists. Skipping creation."
else
    uv venv
    print_status "Virtual environment created"
fi

# Activate virtual environment
echo ""
echo "Activating virtual environment..."
source .venv/bin/activate
print_status "Virtual environment activated"

# Install dependencies
echo ""
echo "Installing Python dependencies..."
echo "This may take several minutes (downloading PyTorch is large)..."
pip install -e ".[$EXTRA]"
print_status "Dependencies installed"

# Build Rust tokenizer
if command_exists cargo; then
    echo ""
    echo "Building Rust BPE tokenizer..."
    cd rustbpe
    cargo build --release
    cd ..
    print_status "Rust tokenizer built successfully"
else
    print_warning "Skipping Rust tokenizer build (Cargo not available)"
fi

# Run verification
echo ""
echo "Verifying installation..."
python3 -c "import torch; print(f'PyTorch version: {torch.__version__}')" && print_status "PyTorch imported successfully"

if [ "$EXTRA" = "gpu" ]; then
    python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA devices: {torch.cuda.device_count()}')" && print_status "CUDA verified"
fi

# Create a quick reference file
echo ""
echo "Creating quick reference file (QUICKSTART.md)..."
cat > QUICKSTART.md << 'EOF'
# Quick Start Reference

## Activate Environment

```bash
source .venv/bin/activate
```

## Common Commands

### Test on CPU (quick validation)
```bash
# See dev/runcpu.sh for minimal CPU training example
bash dev/runcpu.sh
```

### Train Model (GPU required for full speedrun)
```bash
# Speedrun: ~4 hours on 8x H100
bash speedrun.sh

# Or in screen session (recommended)
screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
# Detach: Ctrl+A then D
# Reattach: screen -r speedrun
```

### Chat with Model
```bash
# Web interface
python -m scripts.chat_web

# CLI interface
python -m scripts.chat_cli
```

### Run Tests
```bash
python -m pytest tests/ -v
```

## Useful Commands

```bash
# Check GPU
nvidia-smi

# Monitor training
tail -f speedrun.log

# Package for analysis
files-to-prompt . -e py -e md -e rs -e html -e toml -e sh --ignore "*target*" --cxml > packaged.txt
```

## Documentation

- Setup: [SETUP.md](SETUP.md)
- Best Practices: [BEST_PRACTICES.md](BEST_PRACTICES.md)
- Main README: [README.md](README.md)

## Getting Help

- Issues: https://github.com/karpathy/nanochat/issues
- Discussions: https://github.com/karpathy/nanochat/discussions
EOF

print_status "Created QUICKSTART.md"

# Final message
echo ""
echo "========================================="
print_status "Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Activate the virtual environment:"
echo "   source .venv/bin/activate"
echo ""
echo "2. Read the documentation:"
echo "   - QUICKSTART.md (quick reference)"
echo "   - SETUP.md (detailed setup guide)"
echo "   - BEST_PRACTICES.md (development guidelines)"
echo ""
echo "3. Try a test run:"
if [ "$EXTRA" = "cpu" ]; then
    echo "   bash dev/runcpu.sh"
else
    echo "   bash speedrun.sh"
fi
echo ""
echo "4. Chat with a trained model:"
echo "   python -m scripts.chat_web"
echo ""
echo "Happy hacking!"
echo ""
