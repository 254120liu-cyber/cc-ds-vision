# CC-DS Vision

<p align="center">
  <b>CC-DS Vision — Local Vision for Claude Code + DeepSeek</b><br>
  让 DeepSeek 用户的 Claude Code 具备本地图像理解能力<br>
  Qwen2-VL-7B + llama.cpp · 中文 OCR 强 · 零成本 · 完全离线
</p>

<p align="center">
  <a href="#一键安装"><img src="https://img.shields.io/badge/Install-One_Click-green"></a>
  <a href="#performance"><img src="https://img.shields.io/badge/First_Inference-5~8s-blue"></a>
  <a href="#performance"><img src="https://img.shields.io/badge/Hot_Cache-0.5s-red"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow"></a>
</p>

---

## Why CC-DS Vision? · 为什么需要它？

If you use **DeepSeek** as your Claude Code backend, you've probably noticed: DeepSeek **cannot understand images**. Switching to Claude's vision model costs money — and it adds up.

**CC-DS Vision** solves this: it runs **Qwen2-VL-7B locally** on your GPU, connects to Claude Code via MCP, and gives you image understanding with:

- **Zero cost** — runs entirely on your machine
- **No internet required** — fully offline
- **Strong Chinese OCR** — extracts every character precisely
- **One-click setup** — literally double-click and wait

---

如果你用 **DeepSeek** 作为 Claude Code 的底层模型，会发现它无法理解图片。切到 Claude 视觉模型要额外付费。

**CC-DS Vision** 在你的 GPU 上本地运行 Qwen2-VL-7B，通过 MCP 协议接入 Claude Code：

- **零成本** — 本地推理，不花一分钱
- **离线可用** — 不需要联网
- **中文 OCR 强** — 精确提取每个字
- **一键安装** — 双击等就完事了

---

## 安装 · Installation

### Prerequisites · 前置条件

- Windows 10/11
- NVIDIA GPU (8GB+ VRAM, RTX 3060 or better)
- Node.js ≥ 18
- ~15GB free disk space

### One-Click · 一键安装

1. Download this repository
2. Double-click `setup.bat`
3. Wait for automatic download & setup (10-30 min, depends on network)
4. Restart Claude Code

The installer handles everything:
- Downloads & configures llama.cpp CUDA engine
- Downloads Qwen2-VL-7B model (via ModelScope, fast in China)
- Installs Node.js dependencies
- Writes Claude Code MCP configuration

### Manual · 手动安装

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

## 使用 · Usage

After restarting Claude Code, just talk naturally:

> "描述这张图片"
> "提取图中的所有文字"
> "这张截图里有什么？"
> "帮我分析这个图表"

Claude Code automatically invokes the local Qwen2-VL-7B model.

---

## Performance · 性能

### Speed · 速度

| Scenario 场景 | Speed 速度 |
|--------------|-----------|
| First inference (after startup) 首次识别 | **5-8s** |
| Same image follow-up (hot cache) 同图追问 | **0.5s** |
| Different images (warm) 换图 | **1-7s** |

### Accuracy · 精度

| Capability 能力 | Performance 表现 |
|----------------|-----------------|
| Chinese OCR / Text extraction 中文文字提取 | ⭐⭐⭐⭐⭐ |
| Document understanding 文档理解 | ⭐⭐⭐⭐⭐ |
| UI screenshot analysis 截图分析 | ⭐⭐⭐⭐ |
| Chart data extraction 图表提取 | ⭐⭐⭐⭐ |

---

## Architecture · 技术架构

```
User → Claude Code → CC-DS Vision MCP → llama-server → Qwen2-VL-7B
                            ↓
                     Local GPU Inference
```

| Component 组件 | Technology 技术 |
|---------------|----------------|
| Vision Model | Qwen2-VL-7B-Instruct (Q4_K_M, 4.7GB) |
| Vision Encoder | SigLIP ViT-SO400M (mmproj F32, 2.7GB) |
| Inference Engine | llama.cpp b9071 + CUDA 12.4 |
| Protocol | MCP (Model Context Protocol) + OpenAI-compatible API |

---

## FAQ

**Q: Does it need internet? 需要联网吗？**
A: No. Everything runs locally. 不需要，全部本地推理。

**Q: How does it compare to Claude / GPT-4V?**
A: For daily tasks (OCR, screenshots, documents), the gap is small. Cloud models are better at complex multi-step reasoning, but CC-DS Vision is completely free.

**Q: Why not Ollama?**
A: Ollama's GGUF import doesn't support Qwen2-VL's architecture. llama.cpp has native support.

**Q: Can it run on macOS / Linux?**
A: Currently Windows + CUDA only. macOS/Linux support is planned.

**Q: VRAM usage? · 显存占用多少？**
A: ~7.5 GB total (model 4.2GB + vision encoder 2.6GB + KV cache 0.4GB + overhead).

---

## Star History · 星标历史

If you find this useful, please give it a Star ⭐

如果这个项目对你有帮助，请给个 Star ⭐
