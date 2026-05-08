# CC-DS Vision

<p align="center">
  <b>让 DeepSeek 用户的 Claude Code 具备本地图像理解能力</b><br>
  Qwen2-VL-7B + llama.cpp · 中文 OCR 强 · 零成本 · 完全离线
</p>

<p align="center">
  <a href="README.md">English</a>
</p>

<p align="center">
  <a href="#一键安装"><img src="https://img.shields.io/badge/Install-一键安装-green"></a>
  <a href="#性能"><img src="https://img.shields.io/badge/首次识别-5~8s-blue"></a>
  <a href="#性能"><img src="https://img.shields.io/badge/热缓存-0.5s-red"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow"></a>
</p>

---

## 为什么需要 CC-DS Vision？

如果你用 **DeepSeek** 作为 Claude Code 的底层模型，会发现它无法理解图片。切到 Claude 视觉模型要额外付费。

**CC-DS Vision** 在你的 GPU 上本地运行 Qwen2-VL-7B，通过 MCP 协议接入 Claude Code：

- **零成本** — 本地推理，不花一分钱
- **离线可用** — 不需要联网
- **中文 OCR 强** — 精确提取每个字
- **一键安装** — 双击等就完事了

---

## 安装

### 前置条件

- Windows 10/11
- NVIDIA GPU（8GB+ 显存，RTX 3060 或更高）
- Node.js ≥ 18
- ~15GB 空闲磁盘空间

### 一键安装

1. 下载本仓库
2. 双击 `setup.bat`
3. 等待自动下载和配置（10-30 分钟，取决于网络）
4. 重启 Claude Code

安装脚本会自动完成以下所有步骤：
- 下载并配置 llama.cpp CUDA 引擎
- 从 ModelScope 下载 Qwen2-VL-7B 模型（国内速度快）
- 安装 Node.js 依赖
- 写入 Claude Code MCP 配置

### 手动安装

```bash
# 1. 安装依赖
npm install

# 2. 下载 llama.cpp → ./llama.cpp/
#    https://github.com/ggml-org/llama.cpp/releases/latest
#    下载：llama-b*-bin-win-cuda-12.4-x64.zip
#    下载：cudart-llama-bin-win-cuda-12.4-x64.zip
#    解压两个文件到 ./llama.cpp/

# 3. 下载模型文件 → ./models/
#    https://modelscope.cn/models/bartowski/Qwen2-VL-7B-Instruct-GGUF
#    Qwen2-VL-7B-Instruct-Q4_K_M.gguf  (~4.7GB)
#    mmproj-Qwen2-VL-7B-Instruct-f32.gguf  (~2.7GB)

# 4. 将 .mcp.json 合并到 ~/.claude/.mcp.json
```

---

## 使用

重启 Claude Code 后，直接自然对话即可：

> "描述这张图片"
> "提取图中的所有文字"
> "这张截图里有什么？"
> "帮我分析这个图表"

Claude Code 会自动调用本地 Qwen2-VL-7B 模型。

---

## 性能

### 速度

| 场景 | 速度 |
|------|------|
| 首次识别（启动后） | **5-8s** |
| 同图追问（热缓存） | **0.5s** |
| 换图识别（预热状态） | **1-7s** |

### 精度

| 能力 | 表现 |
|------|------|
| 中文 OCR / 文字提取 | ★★★★★ |
| 文档理解 | ★★★★★ |
| UI 截图分析 | ★★★★ |
| 图表数据提取 | ★★★★ |

---

## 技术架构

```
用户 → Claude Code → CC-DS Vision MCP → llama-server → Qwen2-VL-7B
                            ↓
                     本地 GPU 推理
```

| 组件 | 技术 |
|------|------|
| 视觉模型 | Qwen2-VL-7B-Instruct（Q4_K_M，4.7GB） |
| 视觉编码器 | SigLIP ViT-SO400M（mmproj F32，2.7GB） |
| 推理引擎 | llama.cpp b9071 + CUDA 12.4 |
| 协议 | MCP（Model Context Protocol）+ OpenAI 兼容 API |

---

## 常见问题

**Q: 需要联网吗？**
A: 不需要，全部本地推理。

**Q: 和 Claude / GPT-4V 比怎么样？**
A: 日常任务（OCR、截图、文档）差距很小。云端模型在复杂多步推理上更强，但 CC-DS Vision 完全免费。

**Q: 为什么不用 Ollama？**
A: Ollama 的 GGUF 导入不支持 Qwen2-VL 的架构，llama.cpp 原生支持。

**Q: 支持 macOS / Linux 吗？**
A: 目前仅支持 Windows + CUDA，macOS/Linux 支持计划中。

**Q: 显存占用多少？**
A: ~7.5 GB（模型 4.2GB + 视觉编码器 2.6GB + KV 缓存 0.4GB + 开销）。

---

## 星标历史

如果这个项目对你有帮助，请给个 Star ⭐
