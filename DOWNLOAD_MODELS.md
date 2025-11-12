# Download Pre-Trained Nanochat Models

Don't want to spend $100-$800 training your own model? You can download pre-trained models and run them locally!

## Available Models

### nanochat-d32 (Official Release)

**Model**: [karpathy/nanochat-d32](https://huggingface.co/karpathy/nanochat-d32)
- **Parameters**: 1.9 billion
- **Training**: 38 billion tokens
- **Cost**: ~$800 to train (you get it FREE!)
- **Performance**: Outperforms GPT-2 (2019)

## How to Download

### Method 1: Using git-lfs (Recommended)

```bash
# Install git-lfs if you haven't already
# On Linux/Mac:
git lfs install

# On Windows:
# Download from https://git-lfs.github.com/

# Clone the model repository
cd /path/to/nanochat
mkdir -p models
cd models
git clone https://huggingface.co/karpathy/nanochat-d32
```

### Method 2: Using huggingface_hub Python library

```bash
# Activate your nanochat virtual environment
source .venv/bin/activate  # Linux/Mac
# OR
.venv\Scripts\activate     # Windows

# Install huggingface_hub
pip install huggingface_hub

# Download the model
python << 'EOF'
from huggingface_hub import snapshot_download

# Download all model files
model_path = snapshot_download(
    repo_id="karpathy/nanochat-d32",
    local_dir="./models/nanochat-d32"
)

print(f"Model downloaded to: {model_path}")
EOF
```

### Method 3: Manual Download from Web

1. Visit https://huggingface.co/karpathy/nanochat-d32
2. Click on "Files and versions" tab
3. Download these files manually:
   - `model.pt` (main model checkpoint)
   - `tokenizer.model` (tokenizer vocabulary)
   - Any config files

## How to Run Inference

Once you've downloaded the model, you can chat with it!

### Option 1: Web Interface (ChatGPT-like UI)

```bash
# Activate environment
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows

# Run the web interface
python -m scripts.chat_web --checkpoint=./models/nanochat-d32/model.pt

# Open your browser to http://localhost:8000
```

### Option 2: Command Line Interface

```bash
# Chat via CLI
python -m scripts.chat_cli --checkpoint=./models/nanochat-d32/model.pt
```

### Option 3: Python Script

```python
from nanochat.engine import Engine
from nanochat.tokenizer import Tokenizer

# Load tokenizer and model
tokenizer = Tokenizer("./models/nanochat-d32/tokenizer.model")
engine = Engine(
    checkpoint_path="./models/nanochat-d32/model.pt",
    tokenizer=tokenizer
)

# Generate response
prompt = "Hello! Tell me a short story about a robot."
response = engine.generate(prompt, max_tokens=200)
print(response)
```

## Disk Space Requirements

- **nanochat-d32**: ~7-8 GB
- Make sure you have at least 10 GB free space

## System Requirements for Inference

### Minimum (CPU)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free
- **Speed**: Slow but works

### Recommended (GPU)
- **GPU**: Any NVIDIA GPU with 8GB+ VRAM
- **RAM**: 16GB system RAM
- **Speed**: Much faster, real-time chat

### Optimal (High-end GPU)
- **GPU**: RTX 3090, 4090, or better
- **RAM**: 32GB system RAM
- **Speed**: Very fast inference

## Alternative: Smaller Models

If you want something even more lightweight, you can:

1. **Train a tiny model on CPU**:
   ```bash
   bash dev/runcpu.sh
   ```
   This trains a small model quickly for experimentation.

2. **Download community models**: Check the [nanochat discussions](https://github.com/karpathy/nanochat/discussions) for community-trained models at different sizes.

## Troubleshooting

### "Out of memory" when loading model

**Solution**: You might need a GPU or more RAM. Try:
- Closing other applications
- Using a machine with more RAM
- Using CPU mode with smaller batch sizes

### Model file not found

**Solution**: Make sure you specify the correct path:
```bash
# Check the actual file location
ls -lh models/nanochat-d32/

# Use the full path if needed
python -m scripts.chat_web --checkpoint=/full/path/to/model.pt
```

### Slow inference

**Solution**:
- Use a GPU instead of CPU
- Reduce `max_tokens` in generation
- Use a smaller model

## Tips for Best Experience

1. **GPU recommended**: While CPU works, GPU gives much better experience
2. **Temperature settings**: Adjust `--temperature` for creativity
   - 0.7 = balanced
   - 1.0 = more creative
   - 0.3 = more focused
3. **Try different prompts**: These models are playful and work well with creative prompts

## Community Resources

- **HuggingFace Hub**: https://huggingface.co/karpathy/nanochat-d32
- **GitHub Discussions**: https://github.com/karpathy/nanochat/discussions
- **Model Card**: Check the HuggingFace repo for model details and limitations

## What Can You Do With This?

Once you have the model running locally:
- ✅ Chat with it like ChatGPT
- ✅ Experiment with prompts
- ✅ Fine-tune it further on your own data
- ✅ Study the code and learn how LLMs work
- ✅ Use it for research or personal projects
- ✅ Modify the inference code
- ✅ Run it completely offline

## Cost Comparison

| Option | Cost | Time | Hardware Needed |
|--------|------|------|-----------------|
| Download pre-trained | $0 | 10-30 min | Just storage |
| Train speedrun ($100 tier) | ~$100 | 4 hours | 8x H100 GPUs |
| Train d32 ($800 tier) | ~$800 | 33 hours | 8x H100 GPUs |

**Recommendation**: Start by downloading the pre-trained model, then train your own later if you want to customize it!

## Next Steps

After downloading and running the model:
1. Read [SETUP.md](SETUP.md) for environment setup
2. Read [BEST_PRACTICES.md](BEST_PRACTICES.md) for tips
3. Explore the code to understand how it works
4. Try customizing prompts and parameters
5. Consider fine-tuning on your own data later

Happy chatting! 🤖
