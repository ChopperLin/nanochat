# Nanochat Best Practices

This guide contains best practices for developing, training, and working with nanochat effectively.

## Table of Contents

- [Development Practices](#development-practices)
- [Training Best Practices](#training-best-practices)
- [Code Organization](#code-organization)
- [Performance Optimization](#performance-optimization)
- [Experimentation & Research](#experimentation--research)
- [Deployment & Production](#deployment--production)

## Development Practices

### Environment Setup

1. **Always use virtual environments**:
   ```bash
   uv venv
   source .venv/bin/activate
   ```

2. **Keep dependencies minimal**:
   - Nanochat intentionally has few dependencies
   - Only add dependencies if absolutely necessary
   - Document why each dependency is needed

3. **Test across Python versions**:
   - Test with Python 3.10, 3.11, and 3.12
   - Use `python -m pytest` for consistency

### Code Quality

1. **Follow the minimalist philosophy**:
   - Nanochat is designed to be readable and hackable
   - Avoid over-abstraction
   - No giant configuration objects or model factories
   - Keep code self-contained and understandable

2. **Documentation**:
   - Write clear docstrings for public APIs
   - Include inline comments for complex logic
   - Update README.md when adding features
   - Keep documentation concise but complete

3. **LLM Usage Disclosure** (per project policy):
   - When submitting PRs, declare any substantial LLM contribution
   - Only include code you fully understand
   - Review and verify all LLM-generated code

### Version Control

1. **Git workflow**:
   ```bash
   # Always work on a feature branch
   git checkout -b feature/my-feature

   # Make atomic commits with clear messages
   git commit -m "Add feature X: brief description"

   # Pull before pushing
   git pull --rebase origin main
   git push origin feature/my-feature
   ```

2. **What NOT to commit**:
   - Model checkpoints (`*.pt`, `*.pth`)
   - Dataset files (`*.bin`, large `.txt` files)
   - Virtual environment (`.venv/`)
   - Build artifacts (`rustbpe/target/`)
   - Logs (`*.log`)
   - Personal configuration files

3. **Commit messages**:
   - Use imperative mood: "Add feature" not "Added feature"
   - First line: concise summary (50 chars or less)
   - Body: detailed explanation if needed
   - Reference issues when applicable

## Training Best Practices

### Resource Management

1. **Start small, scale up**:
   ```bash
   # First, test with tiny model on CPU
   bash dev/runcpu.sh

   # Then try small GPU run
   python -m scripts.base_train -- --depth=10 --max_steps=100

   # Finally, full training
   bash speedrun.sh
   ```

2. **Monitor GPU memory**:
   ```bash
   # Watch GPU utilization in real-time
   watch -n 1 nvidia-smi

   # Or continuous monitoring
   nvidia-smi -l 1
   ```

3. **Manage batch sizes**:
   - Start with default `device_batch_size=32`
   - Reduce to 16, 8, or 4 if OOM
   - The code automatically adjusts gradient accumulation

4. **Use checkpointing**:
   - Training automatically saves checkpoints
   - Don't delete checkpoints until training completes successfully
   - Keep checkpoints from different training stages

### Data Management

1. **Dataset preparation**:
   ```bash
   # Download data shards progressively
   python -m nanochat.dataset -n 100  # Start with 100 shards

   # Download more as needed
   python -m nanochat.dataset -n 450  # For larger models
   ```

2. **Tokenizer training**:
   - Train tokenizer on representative data
   - Save tokenizer artifacts
   - Don't retrain unless data distribution changes significantly

3. **Data efficiency**:
   - Calculate required data: `params * 20 = tokens needed`
   - Multiply tokens by 4.8 to get characters
   - Divide characters by 250M to get number of shards

### Experiment Tracking

1. **Use wandb (optional but recommended)**:
   ```bash
   # Login to wandb
   wandb login

   # Training scripts automatically log if wandb is configured
   ```

2. **Keep training logs**:
   ```bash
   # Log to file
   bash speedrun.sh 2>&1 | tee training.log

   # Or use screen with logging
   screen -L -Logfile speedrun.log -S speedrun bash speedrun.sh
   ```

3. **Document experiments**:
   - Keep a notebook/log of hyperparameters
   - Record model performance metrics
   - Note what worked and what didn't

## Code Organization

### Project Structure

```
nanochat/
├── nanochat/          # Core library code
│   ├── gpt.py         # Model architecture
│   ├── dataloader.py  # Data loading
│   ├── engine.py      # Inference engine
│   └── ...
├── scripts/           # Executable scripts
│   ├── base_train.py  # Training scripts
│   ├── chat_web.py    # Web interface
│   └── ...
├── tasks/             # Evaluation tasks
├── rustbpe/           # Rust tokenizer
├── dev/               # Development utilities
└── tests/             # Unit tests
```

### Adding New Features

1. **Core functionality** goes in `nanochat/`:
   ```python
   # nanochat/my_feature.py
   """Brief module description."""

   def my_function():
       """Function docstring."""
       pass
   ```

2. **Executable scripts** go in `scripts/`:
   ```python
   # scripts/my_script.py
   """Script description."""
   import sys
   from nanochat.configurator import Config

   if __name__ == "__main__":
       cfg = Config()
       # script logic
   ```

3. **Evaluation tasks** go in `tasks/`:
   ```python
   # tasks/my_task.py
   from tasks.common import Task

   class MyTask(Task):
       """Task description."""
       pass
   ```

### Testing

1. **Write tests for new features**:
   ```python
   # tests/test_my_feature.py
   import pytest
   from nanochat.my_feature import my_function

   def test_my_function():
       result = my_function()
       assert result == expected
   ```

2. **Run tests before committing**:
   ```bash
   python -m pytest tests/ -v

   # Run specific test file
   python -m pytest tests/test_rustbpe.py -v -s
   ```

## Performance Optimization

### Training Optimization

1. **Gradient accumulation**:
   - Automatically handled when reducing `device_batch_size`
   - Effective batch size remains constant
   - Trades compute parallelism for memory

2. **Mixed precision training**:
   - Use bfloat16 on modern GPUs (Ampere+)
   - Falls back to float16 on older GPUs
   - Already enabled in training scripts

3. **Distributed training**:
   ```bash
   # Use all available GPUs
   torchrun --standalone --nproc_per_node=8 -m scripts.base_train

   # Use specific GPUs
   CUDA_VISIBLE_DEVICES=0,1,2,3 torchrun --standalone --nproc_per_node=4 -m scripts.base_train
   ```

4. **Compilation** (PyTorch 2.0+):
   - Model compilation may be enabled in configs
   - Provides 10-30% speedup
   - First iteration is slower due to compilation

### Inference Optimization

1. **KV Cache**:
   - Already implemented in `nanochat/engine.py`
   - Speeds up autoregressive generation
   - Reuses past key-value computations

2. **Batch inference**:
   - Process multiple prompts together when possible
   - Improves GPU utilization

3. **Temperature and sampling**:
   ```python
   # More deterministic
   temperature = 0.7

   # More creative
   temperature = 1.0

   # Greedy (deterministic)
   temperature = 0.0
   ```

## Experimentation & Research

### Customizing Your Model

1. **Infusing identity** (see discussions):
   - Generate synthetic data for your persona
   - Mix into midtraining and SFT stages
   - Tune proportion based on desired strength

2. **Adding abilities** (see discussions):
   - Create targeted training data
   - Fine-tune on specific tasks
   - Evaluate before and after

3. **Model architecture**:
   - Primary modification: `--depth` (number of layers)
   - Other hyperparameters in `nanochat/gpt.py`
   - Test small before scaling up

### Evaluation Strategy

1. **Systematic evaluation**:
   ```bash
   # Base model CORE score
   python -m scripts.base_eval

   # Chat evaluations
   python -m scripts.chat_eval

   # Specific task
   python -m scripts.chat_eval -- --task=gsm8k
   ```

2. **Create baselines**:
   - Run evaluation on base model
   - Compare after each modification
   - Track metrics over time

3. **Qualitative testing**:
   - Chat with your model regularly
   - Test edge cases
   - Compare with other models

### Research Workflow

1. **Hypothesis → Experiment → Analysis**:
   - Clearly state what you're testing
   - Change one variable at a time
   - Document results

2. **Reproducibility**:
   - Set random seeds
   - Document all hyperparameters
   - Save model checkpoints
   - Keep training logs

3. **Share findings**:
   - Post in GitHub Discussions
   - Include code, data, and results
   - Help others learn from your experiments

## Deployment & Production

### Serving Your Model

1. **Web interface** (development):
   ```bash
   python -m scripts.chat_web
   ```

2. **API endpoint** (production):
   - FastAPI is already included
   - Extend `scripts/chat_web.py` for your needs
   - Add authentication for public deployment

3. **Performance considerations**:
   - Use GPU for inference when possible
   - Implement request batching
   - Set appropriate timeouts
   - Cache common responses

### Security

1. **Input validation**:
   - Limit input length
   - Sanitize user inputs
   - Implement rate limiting

2. **Output filtering**:
   - Consider content moderation
   - Log problematic outputs
   - Implement safety guardrails

3. **Authentication & Authorization**:
   - Don't expose without auth in production
   - Use API keys or OAuth
   - Implement usage quotas

### Monitoring

1. **Log everything important**:
   - Requests and responses
   - Errors and exceptions
   - Performance metrics
   - Resource usage

2. **Metrics to track**:
   - Requests per second
   - Average latency
   - Error rate
   - GPU utilization
   - Memory usage

3. **Alerting**:
   - Set up alerts for errors
   - Monitor resource exhaustion
   - Track unusual patterns

## Common Pitfalls to Avoid

1. **Don't skip testing small first**:
   - Always test on small scale before full training
   - Saves time and money

2. **Don't ignore OOM errors**:
   - Reduce batch size immediately
   - Don't try to increase memory without understanding the issue

3. **Don't modify too many things at once**:
   - Change one variable at a time
   - Makes debugging much easier

4. **Don't forget to save checkpoints**:
   - Training can be interrupted
   - Checkpoints are your safety net

5. **Don't commit large files**:
   - Use `.gitignore`
   - Store large files separately (e.g., S3, HuggingFace Hub)

6. **Don't train without evaluation**:
   - Regularly evaluate during training
   - Catch issues early

## Resources

- **Official Documentation**: [README.md](README.md)
- **Setup Guide**: [SETUP.md](SETUP.md)
- **GitHub Discussions**: https://github.com/karpathy/nanochat/discussions
- **Issues**: https://github.com/karpathy/nanochat/issues
- **DeepWiki**: https://deepwiki.com/karpathy/nanochat

## Contributing

When contributing to nanochat:

1. Read the existing code to understand the style
2. Keep changes minimal and focused
3. Test thoroughly before submitting PR
4. Disclose LLM usage per project policy
5. Be respectful and constructive

Remember: nanochat is designed to be a clean, minimal, readable codebase. Maintain this philosophy in all contributions.
