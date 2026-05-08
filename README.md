# CC-DS Vision

<p align="center">
  <b>Local Vision for Claude Code + DeepSeek</b><br>
  Give your DeepSeek-powered Claude Code the ability to understand images —<br>
  powered by Qwen2-VL-7B + llama.cpp · Zero cost · Fully offline
</p>

<p align="center">
  <a href="README_CN.md">中文说明</a>
</p>

<p align="center">
  <a href="#one-click-install"><img src="https://img.shields.io/badge/Install-One_Click-green"></a>
  <a href="#performance"><img src="https://img.shields.io/badge/First_Inference-5~8s-blue"></a>
  <a href="#performance"><img src="https://img.shields.io/badge/Hot_Cache-0.5s-red"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow"></a>
</p>

---

## Why CC-DS Vision?

If you use **DeepSeek** as your Claude Code backend, you've probably noticed: DeepSeek **cannot understand images**. Switching to Claude's vision model costs money — and it adds up.

**CC-DS Vision** solves this: it runs **Qwen2-VL-7B locally** on your GPU, connects to Claude Code via MCP, and gives you image understanding with:

- **Zero cost** — runs entirely on your machine
- **No internet required** — fully offline
- **Strong Chinese OCR** — extracts every character precisely
- **One-click setup** — double-click and wait

---

## Installation

### Prerequisites

- Windows 10/11
- NVIDIA GPU (8GB+ VRAM, RTX 3060 or better)
- Node.js ≥ 18
- ~15GB free disk space

### One-Click

1. Download this repository
2. Double-click `setup.bat`
3. Wait for automatic download & setup (10-30 min, depends on network)
4. Restart Claude Code

The installer handles everything:
- Downloads & configures llama.cpp CUDA engine
- Downloads Qwen2-VL-7B model (via ModelScope, fast in China)
- Installs Node.js dependencies
- Writes Claude Code MCP configuration

### Manual

```bash
# 1. Install dependencies
npm install

# 2. Download llama.cpp → ./llama.cpp/
#    https://github.com/ggml-org/llama.cpp/releases/latest
#    Get: llama-b*-bin-win-cuda-12.4-x64.zip
#    Get: cudart-llama-bin-win-cuda-12.4-x64.zip
#    Extract both to ./llama.cpp/

# 3. Download model files → ./models/
#    https://modelscope.cn/models/bartowski/Qwen2-VL-7B-Instruct-GGUF
#    Qwen2-VL-7B-Instruct-Q4_K_M.gguf  (~4.7GB)
#    mmproj-Qwen2-VL-7B-Instruct-f32.gguf  (~2.7GB)

# 4. Merge .mcp.json into ~/.claude/.mcp.json
```

---

## Usage

After restarting Claude Code, just talk naturally:

> "Describe this image"
> "Extract all text from this image"
> "What's in this screenshot?"
> "Help me analyze this chart"

Claude Code automatically invokes the local Qwen2-VL-7B model.

---

## Performance

### Speed

| Scenario | Speed |
|----------|-------|
| First inference (after startup) | **5-8s** |
| Same image follow-up (hot cache) | **0.5s** |
| Different images (warm) | **1-7s** |

### Accuracy

| Capability | Performance |
|------------|-------------|
| Chinese OCR / Text extraction | ★★★★★ |
| Document understanding | ★★★★★ |
| UI screenshot analysis | ★★★★ |
| Chart data extraction | ★★★★ |

---

## Architecture

```
User → Claude Code → CC-DS Vision MCP → llama-server → Qwen2-VL-7B
                            ↓
                     Local GPU Inference
```

| Component | Technology |
|-----------|-----------|
| Vision Model | Qwen2-VL-7B-Instruct (Q4_K_M, 4.7GB) |
| Vision Encoder | SigLIP ViT-SO400M (mmproj F32, 2.7GB) |
| Inference Engine | llama.cpp b9071 + CUDA 12.4 |
| Protocol | MCP (Model Context Protocol) + OpenAI-compatible API |

---

## FAQ

**Q: Does it need internet?**
A: No. Everything runs locally.

**Q: How does it compare to Claude / GPT-4V?**
A: For daily tasks (OCR, screenshots, documents), the gap is small. Cloud models are better at complex multi-step reasoning, but CC-DS Vision is completely free.

**Q: Why not Ollama?**
A: Ollama's GGUF import doesn't support Qwen2-VL's architecture. llama.cpp has native support.

**Q: Can it run on macOS / Linux?**
A: Currently Windows + CUDA only. macOS/Linux support is planned.

**Q: VRAM usage?**
A: ~7.5 GB total (model 4.2GB + vision encoder 2.6GB + KV cache 0.4GB + overhead).

---

## Star History

If you find this useful, please give it a Star ⭐
