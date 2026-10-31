---
name: karpathy-ml-from-scratch
description: Build neural networks from scratch using Andrej Karpathy's minimal, educational approach. Covers micrograd (autograd engine), nanoGPT (transformer), and general principles for implementing ML fundamentals with minimal dependencies.
---

# Karpathy-Style ML From Scratch

This skill encodes Andrej Karpathy's approach to building machine learning systems from first principles — minimal code, maximum understanding.

## Core Philosophy

1. **Build from scratch** — Don't import `torch.nn`; write your own `Linear`, `LayerNorm`, `MultiHeadAttention`
2. **Minimal dependencies** — NumPy only (or pure Python). No PyTorch/TensorFlow/JAX for the core logic
3. **Bottom-up understanding** — Start with scalar autograd (micrograd), build up to transformers (nanoGPT)
4. **Readable over optimized** — Clean, explicit code that teaches; avoid clever tricks
5. **Notebook-first** — Develop in Jupyter; export to `.py` when stable

---

## The Progression (Karpathy's Curriculum)

### Level 1: Micrograd — Scalar Autograd Engine
**Goal**: Understand backpropagation by building a tiny autograd engine for scalars

```python
# Core concepts to implement:
# - Value class with .data, .grad, ._backward(), ._prev
# - Operations: +, *, -, /, **, tanh, relu
# - Topological sort for backward pass
# - Neuron/MLP using Value
```

**Key files to study**: `micrograd/engine.py`, `micrograd/nn.py`

### Level 2: Micrograd → MiniTorch — Tensor Autograd
**Goal**: Generalize to N-dimensional tensors

```python
# Extend Value → Tensor
# - Broadcasting rules
# - View/reshape/transpose
# - Matrix multiplication (@)
# - Conv2d (im2col + gemm)
# - Autograd with gradient accumulation
```

### Level 3: NanoGPT — Transformer from Scratch
**Goal**: Build a working GPT in ~300 lines

```python
# Components to implement:
# - Tokenizer (byte-level BPE or char-level)
# - Embedding + Positional Encoding
# - LayerNorm, Linear, Dropout
# - MultiHeadAttention (causal mask!)
# - FeedForward (GeLU)
# - Block (Attn + FFN + Residuals)
# - GPT (stack of Blocks + LM head)
# - Training loop: forward, loss, backward, optimizer step
# - Generation: temperature sampling, top-k
```

**Target**: Train on Shakespeare (1M chars) in ~5 min on CPU

### Level 4: Scaling Up
- **DataLoader** with shuffling, batching
- **Optimizers**: SGD, AdamW (with weight decay decoupled)
- **Learning rate schedules**: cosine decay, warmup
- **Mixed precision** (FP16/BF16) — optional but educational
- **Distributed**: DDP basics (single-node multi-GPU)

---

## Karpathy's Coding Patterns

### 1. Explicit Shape Comments
```python
# x: (B, T, C)  # Batch, Time, Channels
# w: (C, C)     # Weight matrix
# out: (B, T, C)
```

### 2. Minimal Classes — Functions Preferred
```python
# Instead of nn.Module subclasses, use functions + dicts
def linear(x, w, b): return x @ w + b
def layernorm(x, w, b, eps=1e-5): ...
```

### 3. Manual Backward for Learning, Then Autograd
```python
# Phase 1: Write manual .backward() for each op (educational)
# Phase 2: Replace with autograd engine (production)
```

### 4. Config as Simple Dataclass/Dict
```python
@dataclass
class GPTConfig:
    vocab_size: int = 50304
    n_layer: int = 12
    n_head: int = 12
    n_embd: int = 768
    block_size: int = 1024
    dropout: float = 0.1
```

### 5. Training Loop — Explicit, No Callbacks
```python
for iter in range(max_iters):
    xb, yb = get_batch('train')
    logits, loss = model(xb, yb)
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()
    # Optional: eval, checkpoint, lr schedule
```

---

## Recommended Project Structure

```
karpathy-ml/
├── micrograd/
│   ├── engine.py      # Value class, autograd
│   ├── nn.py          # Neuron, Layer, MLP
│   └── test_micrograd.ipynb
├── minitorch/
│   ├── tensor.py      # Tensor + autograd
│   ├── ops.py         # Elementwise, matmul, conv
│   ├── nn.py          # Modules: Linear, Conv2d, etc.
│   └── optim.py       # SGD, AdamW
├── nanogpt/
│   ├── model.py       # GPT, Block, Attention
│   ├── train.py       # Training loop
│   ├── data.py        # Tokenizer, DataLoader
│   └── sample.py      # Generation
├── README.md
└── requirements.txt   # numpy only (maybe matplotlib)
```

---

## Common Pitfalls (Karpathy's "Failure Catalogue")

| Pitfall | Fix |
|---------|-----|
| Forgetting causal mask in attention | `mask = torch.tril(torch.ones(T, T))` |
| Wrong transpose in `q @ k.T` | Shapes: `(B, nh, T, hs) @ (B, nh, hs, T) → (B, nh, T, T)` |
| LayerNorm before/after residual | Pre-norm (modern): `x + Attn(LN(x))` |
| Weight decay on bias/layernorm | AdamW: `param_groups = [{params: decay}, {params: no_decay, weight_decay: 0}]` |
| Not tying input/output embeddings | `lm_head.weight = token_embedding.weight` |
| Gradient accumulation bugs | `loss = loss / grad_accum_steps` then `loss.backward()` |

---

## Debugging Checklist

When something doesn't train:
1. **Overfit one batch** — loss should go to ~0
2. **Check gradient norms** — `param.grad.norm()` per layer
3. **Verify shapes at every step** — print in forward
4. **Compare with PyTorch reference** — swap your Linear for `nn.Linear`
5. **Visualize attention** — `attn[0].detach().cpu().numpy()`

---

## Resources (Primary Sources)

- **micrograd**: https://github.com/karpathy/micrograd + [YouTube](https://youtu.be/VMj-3S1tku0)
- **nanoGPT**: https://github.com/karpathy/nanoGPT + [YouTube](https://youtu.be/kCc8FmEb1nY)
- **Zero to Hero** playlist: https://www.youtube.com/playlist?list=PLAqhIrjkxbuWI23v9cThsA9GvCAUhRvKZ
- **The spelled-out intro to LLMs**: https://youtu.be/zduSFxRajkE

---

## Usage in OpenCode

Invoke this skill when:
- Building any neural net component from scratch
- Debugging autograd/backprop issues
- Implementing transformers, attention, or LLMs
- Wanting minimal, readable ML code
- Teaching/learning ML fundamentals

**Example prompts**:
- "Implement LayerNorm from scratch with backward pass"
- "Write a causal self-attention module in NumPy"
- "Build a tiny GPT that overfits one batch of Shakespeare"
- "Debug why my manual backprop doesn't match PyTorch"