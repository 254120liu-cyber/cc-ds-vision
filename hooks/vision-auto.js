#!/usr/bin/env node
// CC-DS Vision auto-detection hook for Claude Code
// Detects when user mentions images and injects context to trigger describe_image
const { readdirSync, statSync } = require("fs");
const { resolve } = require("path");

async function main() {
  let input = "";
  for await (const chunk of process.stdin) {
    input += chunk;
  }

  let hook;
  try {
    hook = JSON.parse(input);
  } catch {
    process.exit(0);
  }

  const prompt = (hook.prompt || "").toLowerCase();
  const cwd = hook.cwd || process.cwd();

  // Keywords that indicate user is talking about images
  const imageKeywords = [
    "图片", "图像", "照片", "截图", "画面", "看图", "识图",
    "image", "photo", "screenshot", "picture", "snapshot",
    "识别", "提取文字", "ocr", "描述这张", "分析这张",
    "这个目录下的图", "文件夹里的图",
  ];

  const hasImageKeyword = imageKeywords.some((kw) => prompt.includes(kw));

  // Check if current directory has image files
  let hasImages = false;
  let imageFiles = [];
  try {
    const files = readdirSync(cwd);
    imageFiles = files.filter((f) => {
      const ext = f.toLowerCase().split(".").pop();
      return ["png", "jpg", "jpeg", "webp", "bmp", "gif"].includes(ext);
    });
    hasImages = imageFiles.length > 0;
  } catch {
    // Can't read directory, skip
  }

  if (!hasImageKeyword && !hasImages) {
    // Check parent directory too
    process.exit(0);
  }

  // Build context injection
  let context = "## Image Context Detected\n\n";

  if (hasImages && imageFiles.length > 0) {
    context += `**Images found in current directory (${cwd}):**\n`;
    for (const f of imageFiles) {
      context += `- \`${f}\`\n`;
    }
    context += "\n";
  }

  context += `**REMINDER: You have \`describe_image\` tool (cc-ds-vision MCP) — this IS your vision.** `;
  context += `If the user is asking about these images, call \`describe_image(path="...")\` on each one FIRST before responding. `;
  context += `Never say you cannot read images.`;

  console.log(JSON.stringify({ additionalContext: context }));
}

main().catch(() => process.exit(0));
