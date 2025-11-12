@echo off
REM Nanochat Speedrun Script for Windows
REM Equivalent to speedrun.sh for Windows users
REM This trains the $100 tier nanochat model

SETLOCAL EnableDelayedExpansion

echo =========================================
echo Nanochat Speedrun for Windows
echo =========================================
echo.

REM Check if virtual environment exists
if not exist ".venv\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found!
    echo Please run setup first:
    echo   uv venv
    echo   .venv\Scripts\activate
    echo   pip install -e ".[gpu]"
    exit /b 1
)

REM Activate virtual environment
echo Activating virtual environment...
call .venv\Scripts\activate.bat

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found in virtual environment!
    exit /b 1
)

echo.
echo Starting training pipeline...
echo.

REM Step 1: Train tokenizer
echo =========================================
echo Step 1: Training BPE tokenizer
echo =========================================
python -m scripts.tok_train
if errorlevel 1 (
    echo ERROR: Tokenizer training failed!
    exit /b 1
)

REM Step 2: Download training data
echo.
echo =========================================
echo Step 2: Downloading training data
echo =========================================
python -m nanochat.dataset -n 100
if errorlevel 1 (
    echo ERROR: Data download failed!
    exit /b 1
)

REM Step 3: Base model training
echo.
echo =========================================
echo Step 3: Training base model
echo =========================================
REM Use torchrun for multi-GPU if available, otherwise single GPU
python -m scripts.base_train
if errorlevel 1 (
    echo ERROR: Base training failed!
    exit /b 1
)

REM Step 4: Evaluate base model
echo.
echo =========================================
echo Step 4: Evaluating base model
echo =========================================
python -m scripts.base_eval
if errorlevel 1 (
    echo WARNING: Base evaluation failed (continuing...)
)

REM Step 5: Calculate loss on validation set
echo.
echo =========================================
echo Step 5: Calculating validation loss
echo =========================================
python -m scripts.base_loss
if errorlevel 1 (
    echo WARNING: Loss calculation failed (continuing...)
)

REM Step 6: Midtraining
echo.
echo =========================================
echo Step 6: Midtraining on chat data
echo =========================================
python -m scripts.mid_train
if errorlevel 1 (
    echo ERROR: Midtraining failed!
    exit /b 1
)

REM Step 7: Supervised fine-tuning
echo.
echo =========================================
echo Step 7: Supervised fine-tuning (SFT)
echo =========================================
python -m scripts.chat_sft
if errorlevel 1 (
    echo ERROR: SFT failed!
    exit /b 1
)

REM Step 8: Chat evaluation
echo.
echo =========================================
echo Step 8: Evaluating chat model
echo =========================================
python -m scripts.chat_eval
if errorlevel 1 (
    echo WARNING: Chat evaluation failed (continuing...)
)

REM Done!
echo.
echo =========================================
echo Training Complete!
echo =========================================
echo.
echo Your model is ready! To chat with it:
echo   .venv\Scripts\activate
echo   python -m scripts.chat_web
echo.
echo Then open your browser to http://localhost:8000
echo.

ENDLOCAL
