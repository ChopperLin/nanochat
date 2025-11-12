@echo off
REM Nanochat Setup Script for Windows
REM This script helps you set up nanochat on Windows

SETLOCAL EnableDelayedExpansion

echo =========================================
echo Nanochat Setup for Windows
echo =========================================
echo.

REM Check Python
echo Checking prerequisites...
echo.

python --version >nul 2>&1
if errorlevel 1 (
    echo [X] Python is not installed or not in PATH
    echo.
    echo Please install Python 3.10 or higher from:
    echo https://www.python.org/downloads/
    echo.
    echo Make sure to check "Add Python to PATH" during installation!
    exit /b 1
) else (
    for /f "tokens=2" %%i in ('python --version') do set PYTHON_VERSION=%%i
    echo [✓] Python !PYTHON_VERSION! found
)

REM Check uv
uv --version >nul 2>&1
if errorlevel 1 (
    echo [X] uv is not installed
    echo.
    echo To install uv, run this in PowerShell (as Administrator):
    echo   irm https://astral.sh/uv/install.ps1 ^| iex
    echo.
    echo Then restart this script.
    exit /b 1
) else (
    for /f "tokens=2" %%i in ('uv --version') do set UV_VERSION=%%i
    echo [✓] uv !UV_VERSION! found
)

REM Check Cargo
cargo --version >nul 2>&1
if errorlevel 1 (
    echo [!] Cargo/Rust is not installed
    echo.
    echo Rust is optional but recommended for the custom tokenizer.
    echo To install, visit: https://rustup.rs/
    echo.
    set CARGO_AVAILABLE=0
) else (
    for /f "tokens=2" %%i in ('cargo --version') do set CARGO_VERSION=%%i
    echo [✓] Cargo !CARGO_VERSION! found
    set CARGO_AVAILABLE=1
)

REM Check for GPU
nvidia-smi >nul 2>&1
if errorlevel 1 (
    echo [!] No NVIDIA GPU detected
    echo.
    set INSTALL_MODE=cpu
    echo Installing in CPU mode...
) else (
    echo [✓] NVIDIA GPU detected
    echo.
    echo Installation mode:
    echo   1) GPU mode (recommended - you have a GPU)
    echo   2) CPU mode (slower, for testing)
    echo.
    set /p MODE_CHOICE="Choose mode (1 or 2): "

    if "!MODE_CHOICE!"=="1" (
        set INSTALL_MODE=gpu
        echo Installing in GPU mode...
    ) else (
        set INSTALL_MODE=cpu
        echo Installing in CPU mode...
    )
)

echo.

REM Create virtual environment
if exist ".venv" (
    echo [!] Virtual environment already exists. Skipping creation.
) else (
    echo Creating virtual environment...
    uv venv
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment!
        exit /b 1
    )
    echo [✓] Virtual environment created
)

echo.

REM Activate and install
echo Activating virtual environment...
call .venv\Scripts\activate.bat

echo.
echo Installing Python dependencies...
echo This may take several minutes (PyTorch is large)...
echo.

pip install -e ".[%INSTALL_MODE%]"
if errorlevel 1 (
    echo ERROR: Failed to install dependencies!
    exit /b 1
)

echo [✓] Dependencies installed

REM Build Rust tokenizer if Cargo is available
if !CARGO_AVAILABLE!==1 (
    echo.
    echo Building Rust BPE tokenizer...
    cd rustbpe
    cargo build --release
    if errorlevel 1 (
        echo WARNING: Rust tokenizer build failed
        echo The Python tokenizer will be used as fallback
    ) else (
        echo [✓] Rust tokenizer built successfully
    )
    cd ..
)

REM Verify installation
echo.
echo Verifying installation...
python -c "import torch; print(f'PyTorch version: {torch.__version__}')" >nul 2>&1
if errorlevel 1 (
    echo ERROR: PyTorch import failed!
    exit /b 1
) else (
    echo [✓] PyTorch verified
)

if "%INSTALL_MODE%"=="gpu" (
    python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
    python -c "import torch; print(f'CUDA devices: {torch.cuda.device_count()}')"
)

REM Create quick reference
echo.
echo Creating QUICKSTART.md...
(
echo # Quick Start Reference for Windows
echo.
echo ## Activate Environment
echo.
echo ```powershell
echo .venv\Scripts\activate
echo ```
echo.
echo ## Common Commands
echo.
echo ### Train Model ^(GPU recommended^)
echo ```powershell
echo # Full speedrun
echo speedrun.bat
echo ```
echo.
echo ### Chat with Model
echo ```powershell
echo # Web interface
echo python -m scripts.chat_web
echo.
echo # CLI interface
echo python -m scripts.chat_cli
echo ```
echo.
echo ### Individual Training Steps
echo ```powershell
echo # Train tokenizer
echo python -m scripts.tok_train
echo.
echo # Download data
echo python -m nanochat.dataset -n 100
echo.
echo # Train base model
echo python -m scripts.base_train
echo.
echo # Evaluate
echo python -m scripts.base_eval
echo ```
echo.
echo ### Run Tests
echo ```powershell
echo python -m pytest tests/ -v
echo ```
echo.
echo ## Documentation
echo.
echo - Setup: [SETUP.md](SETUP.md^) - See Windows section
echo - Best Practices: [BEST_PRACTICES.md](BEST_PRACTICES.md^)
echo - Main README: [README.md](README.md^)
echo.
echo ## Getting Help
echo.
echo - Issues: https://github.com/karpathy/nanochat/issues
echo - Discussions: https://github.com/karpathy/nanochat/discussions
) > QUICKSTART-WINDOWS.md

echo [✓] Created QUICKSTART-WINDOWS.md

REM Final message
echo.
echo =========================================
echo [✓] Setup Complete!
echo =========================================
echo.
echo Next steps:
echo.
echo 1. Activate the virtual environment:
echo    .venv\Scripts\activate
echo.
echo 2. Read the documentation:
echo    - QUICKSTART-WINDOWS.md ^(quick reference^)
echo    - SETUP.md ^(detailed guide - Windows section^)
echo    - BEST_PRACTICES.md ^(development guidelines^)
echo.
if "%INSTALL_MODE%"=="gpu" (
    echo 3. Run training:
    echo    speedrun.bat
) else (
    echo 3. Run a small test:
    echo    python -m scripts.tok_train
)
echo.
echo 4. Chat with a trained model:
echo    python -m scripts.chat_web
echo.
echo Happy hacking!
echo.

ENDLOCAL
pause
