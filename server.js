#!/usr/bin/env node
/**
 * CC-DS Vision — Local Vision Model MCP Server
 * Uses Qwen2-VL-7B via llama.cpp to give Claude Code image understanding.
 * Optimized for Chinese OCR, zero cost, fully local.
 */
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { readFileSync, existsSync, statSync } from "fs";
import { resolve, dirname } from "path";
import { spawn } from "child_process";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PLUGIN_DIR = resolve(__dirname);

const LLAMA_HOST = process.env.LLAMA_HOST || "http://127.0.0.1:8081";
const LLAMA_MODEL = process.env.LLAMA_VISION_MODEL || "qwen2-vl";
const LLAMA_DIR = resolve(PLUGIN_DIR, process.env.LLAMA_DIR || "./llama.cpp");
const MODEL_PATH = resolve(PLUGIN_DIR, process.env.LLAMA_MODEL_PATH || "./models/Qwen2-VL-7B-Instruct-Q4_K_M.gguf");
const MMPROJ_PATH = resolve(PLUGIN_DIR, process.env.LLAMA_MMPROJ_PATH || "./models/mmproj-Qwen2-VL-7B-Instruct-f32.gguf");

let llamaProcess = null;

const WARMUP_IMG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==";
const IMAGE_EXTS = ["png", "jpg", "jpeg", "webp", "bmp", "gif"];
const EXTRACTION_RE = /提取|文字|OCR|识别|列出|所有|extract/i;

const MAX_IMAGE_BYTES = 50 * 1024 * 1024;

function toBase64(filePath) {
  const abs = resolve(filePath);
  const size = statSync(abs).size;
  if (size > MAX_IMAGE_BYTES) {
    throw new Error(`Image too large (${(size / 1024 / 1024).toFixed(1)}MB). Max 50MB.`);
  }
  return readFileSync(abs).toString("base64");
}

function mimeType(filePath) {
  const ext = filePath.split(".").pop().toLowerCase();
  const map = { png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg", webp: "image/webp", gif: "image/gif", bmp: "image/bmp" };
  return map[ext] || "image/png";
}

function checkServer() {
  return fetch(`${LLAMA_HOST}/health`, { signal: AbortSignal.timeout(2000) })
    .then(r => r.ok).catch(() => false);
}

async function startLlamaServer() {
  const alive = await checkServer();
  if (alive) {
    console.error("[CC-DS] llama-server already running on port 8081");
    await warmupVisionEncoder();
    return;
  }

  const llamaExe = `${LLAMA_DIR}/llama-server.exe`;
  if (!existsSync(llamaExe)) {
    console.error("[CC-DS] llama.cpp not found at:", LLAMA_DIR);
    console.error("[CC-DS] Please run setup.bat first, or download from:");
    console.error("[CC-DS]   https://github.com/ggml-org/llama.cpp/releases/latest");
    console.error("[CC-DS]   (download llama-b*-bin-win-cuda-12.4-x64.zip + cudart-llama-bin-win-cuda-12.4-x64.zip)");
    return;
  }
  if (!existsSync(MODEL_PATH)) {
    console.error("[CC-DS] Model not found at:", MODEL_PATH);
    console.error("[CC-DS] Please download from ModelScope:");
    console.error("[CC-DS]   https://modelscope.cn/models/bartowski/Qwen2-VL-7B-Instruct-GGUF");
    console.error("[CC-DS] Files needed: Qwen2-VL-7B-Instruct-Q4_K_M.gguf + mmproj-Qwen2-VL-7B-Instruct-f32.gguf");
    return;
  }
  if (!existsSync(MMPROJ_PATH)) {
    console.error("[CC-DS] mmproj not found at:", MMPROJ_PATH);
    console.error("[CC-DS] Please also download mmproj-Qwen2-VL-7B-Instruct-f32.gguf from ModelScope");
    return;
  }

  console.error("[CC-DS] Starting llama-server...");
  llamaProcess = spawn(
    llamaExe,
    ["-m", MODEL_PATH, "--mmproj", MMPROJ_PATH, "--port", "8081", "--host", "127.0.0.1",
     "-ngl", "99", "--ctx-size", "8192", "--no-warmup", "-tb", "20", "--prio", "2"],
    { stdio: "ignore", detached: false }
  );

  for (let i = 0; i < 60; i++) {
    await new Promise(r => setTimeout(r, 2000));
    if (await checkServer()) {
      console.error("[CC-DS] llama-server started successfully");
      await warmupVisionEncoder();
      return;
    }
  }
  console.error("[CC-DS] Warning: llama-server may still be loading (large model)");
}

async function warmupVisionEncoder() {
  try {
    console.error("[CC-DS] Warming up vision encoder...");
    await fetch(`${LLAMA_HOST}/v1/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: LLAMA_MODEL,
        messages: [{ role: "user", content: [
          { type: "image_url", image_url: { url: `data:image/png;base64,${WARMUP_IMG}` } },
          { type: "text", text: "." }
        ]}],
        max_tokens: 1, temperature: 0,
      }),
      signal: AbortSignal.timeout(30000),
    });
    console.error("[CC-DS] Vision encoder warmup complete");
  } catch (e) {
    console.error("[CC-DS] Warmup failed (non-critical):", e.message);
  }
}

function stopLlamaServer() {
  if (llamaProcess) {
    console.error("[CC-DS] Stopping llama-server...");
    try {
      llamaProcess.kill("SIGTERM");
    } catch {
      // fallback for Windows
      try { llamaProcess.kill(); } catch {}
    }
    llamaProcess = null;
  }
}

async function describeImage(path, prompt, options = {}) {
  if (!llamaReady) {
    throw new Error("Vision model is still loading. Please wait a moment and try again.");
  }
  const dataUrl = `data:${mimeType(path)};base64,${toBase64(path)}`;
  const defaultPrompt = "请详细描述这张图片的内容。如果是UI截图，请描述界面布局和功能；如果是图表，请提取数据；如果有文字，请完整提取所有文字。";
  const finalPrompt = prompt || defaultPrompt;
  const isExtraction = EXTRACTION_RE.test(finalPrompt);

  const body = {
    model: LLAMA_MODEL,
    messages: [{
      role: "user",
      content: [
        { type: "image_url", image_url: { url: dataUrl } },
        { type: "text", text: finalPrompt }
      ]
    }],
    max_tokens: options.max_tokens || (isExtraction ? 800 : 512),
    temperature: options.temperature ?? (isExtraction ? 0.1 : 0.3),
    stream: false,
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 120_000);

  try {
    const resp = await fetch(`${LLAMA_HOST}/v1/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    if (!resp.ok) {
      const text = await resp.text().catch(() => "");
      if (resp.status === 503) {
        throw new Error("Model is still loading. Please wait 30 seconds and try again.");
      }
      throw new Error(`llama.cpp API error ${resp.status}: ${text || resp.statusText}`);
    }
    const data = await resp.json();
    return data.choices?.[0]?.message?.content || JSON.stringify(data);
  } catch (e) {
    if (e.name === "AbortError") {
      throw new Error("Image analysis timed out. Try a smaller image (under 3MB).");
    }
    throw e;
  } finally {
    clearTimeout(timeout);
  }
}

let llamaReady = false;

// ── CRITICAL: Connect MCP FIRST, then start llama-server in background ──
// Claude Code has a short timeout for MCP initialization handshake.
// If we block on llama-server startup before connecting, Claude Code times out
// and never registers the describe_image tool.

const server = new Server(
  { name: "cc-ds-vision", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [{
    name: "describe_image",
    description: "【MUST USE for any image task】Analyze and understand an image using local Qwen2-VL-7B vision model. Supports PNG/JPG/WEBP/BMP. Strong Chinese OCR and text extraction. Zero cost, fully offline. You MUST call this tool whenever: (1) the user mentions or references an image file, (2) asks about content of a picture/screenshot/photo, (3) needs to extract text from an image, (4) wants to analyze or work with any image. This tool IS your vision capability — NEVER say you cannot read or see images, because you CAN by invoking this tool. Always call it FIRST before responding to any image-related request.",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Absolute path to the image file (e.g., C:\\Users\\xxx\\Desktop\\photo.png)"
        },
        prompt: {
          type: "string",
          description: "Optional custom analysis prompt. Default provides comprehensive description with text extraction."
        },
      },
      required: ["path"],
    },
  }],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  if (name === "describe_image") {
    try {
      const result = await describeImage(args.path, args.prompt);
      return { content: [{ type: "text", text: result }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Error: ${e.message}` }], isError: true };
    }
  }
  throw new Error(`Unknown tool: ${name}`);
});

process.on("exit", stopLlamaServer);
process.on("SIGINT", () => { stopLlamaServer(); process.exit(); });
process.on("SIGTERM", () => { stopLlamaServer(); process.exit(); });

// Step 1: Connect MCP transport IMMEDIATELY — Claude Code needs this within seconds
const transport = new StdioServerTransport();
await server.connect(transport);
console.error("[cc-ds-vision] MCP server connected, tool registered");

// Step 2: Start llama-server in background (after MCP is connected)
startLlamaServer().then(() => {
  llamaReady = true;
  console.error("[cc-ds-vision] Vision model ready for requests");
}).catch(e => {
  console.error("[cc-ds-vision] Failed to start llama-server:", e.message);
});
