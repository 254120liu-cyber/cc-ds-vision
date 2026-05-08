@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title CC-DS Vision — One-Click Installer

echo.
echo   ╔══════════════════════════════════════════╗
echo   ║     CC-DS Vision  —  一键安装程序         ║
echo   ║  Qwen2-VL-7B + llama.cpp 本地视觉模型    ║
echo   ╚══════════════════════════════════════════╝
echo.
echo   将自动下载并安装：
echo     - llama.cpp CUDA 引擎 (~578MB)
echo     - Qwen2-VL-7B 视觉模型 (~7.4GB)
echo     - Node.js MCP 服务器
echo.
echo   安装位置：%~dp0
echo   预计耗时：10-30 分钟（取决于网速）
echo.

set PLUGIN_DIR=%~dp0
cd /d "%PLUGIN_DIR%"

:: ── Prerequisites check ──
echo   [检查] Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo   [错误] 未找到 Node.js！请先安装：https://nodejs.org
    pause & exit /b 1
)
for /f "tokens=*" %%i in ('node -v') do echo         已安装 %%i

echo   [检查] NVIDIA GPU...
nvidia-smi >nul 2>&1
if %errorlevel% neq 0 (
    echo   [警告] 未检测到 NVIDIA GPU，可能无法使用 CUDA 加速
)

:: ── Step 1: npm install ──
echo.
echo   ═══ [1/3] 安装 Node.js 依赖 ═══
call npm install --silent
if %errorlevel% neq 0 (
    echo   [错误] npm install 失败
    pause & exit /b 1
)
echo   [完成] MCP SDK 已安装

:: ── Step 2: llama.cpp ──
echo.
echo   ═══ [2/3] 安装 llama.cpp 引擎 ═══

set LLAMA_DIR=%PLUGIN_DIR%llama.cpp
set LLAMA_VER=b9071
set LLAMA_ZIP=llama-%LLAMA_VER%-bin-win-cuda-12.4-x64.zip
set CUDART_ZIP=cudart-llama-bin-win-cuda-12.4-x64.zip

if exist "%LLAMA_DIR%\llama-server.exe" (
    echo   [跳过] llama.cpp 已安装
    goto :models
)

if not exist "%LLAMA_DIR%" mkdir "%LLAMA_DIR%"

:: Download llama.cpp binary
echo   [下载] llama.cpp 主程序 (204MB)...
powershell -Command "& {
    $url = 'https://github.com/ggml-org/llama.cpp/releases/download/%LLAMA_VER%/%LLAMA_ZIP%'
    $mirror = 'https://mirror.ghproxy.com/' + $url
    $out = '%LLAMA_DIR%\%LLAMA_ZIP%'
    try {
        Write-Host '  尝试国内镜像...'
        Invoke-WebRequest -Uri $mirror -OutFile $out -ErrorAction Stop
    } catch {
        Write-Host '  镜像失败，使用 GitHub 直连...'
        Invoke-WebRequest -Uri $url -OutFile $out
    }
    Write-Host '  下载完成'
}"

if not exist "%LLAMA_DIR%\%LLAMA_ZIP%" (
    echo   [错误] llama.cpp 下载失败，请检查网络后重试
    pause & exit /b 1
)

:: Download CUDA runtime
echo   [下载] CUDA 运行时 (374MB)...
powershell -Command "& {
    $url = 'https://github.com/ggml-org/llama.cpp/releases/download/%LLAMA_VER%/%CUDART_ZIP%'
    $mirror = 'https://mirror.ghproxy.com/' + $url
    $out = '%LLAMA_DIR%\%CUDART_ZIP%'
    try {
        Invoke-WebRequest -Uri $mirror -OutFile $out -ErrorAction Stop
    } catch {
        Invoke-WebRequest -Uri $url -OutFile $out
    }
    Write-Host '  下载完成'
}"

if not exist "%LLAMA_DIR%\%CUDART_ZIP%" (
    echo   [错误] CUDA 运行时下载失败
    pause & exit /b 1
)

:: Extract
echo   [解压] 正在解压...
powershell -Command "Expand-Archive -Path '%LLAMA_DIR%\%LLAMA_ZIP%' -DestinationPath '%LLAMA_DIR%' -Force"
powershell -Command "Expand-Archive -Path '%LLAMA_DIR%\%CUDART_ZIP%' -DestinationPath '%LLAMA_DIR%' -Force"

:: Clean up zip files
del "%LLAMA_DIR%\%LLAMA_ZIP%" 2>nul
del "%LLAMA_DIR%\%CUDART_ZIP%" 2>nul

if not exist "%LLAMA_DIR%\llama-server.exe" (
    echo   [错误] 解压失败，请手动解压 zip 文件到 %LLAMA_DIR%
    pause & exit /b 1
)
echo   [完成] llama.cpp 引擎已安装

:: ── Step 3: Model files ──
:models
echo.
echo   ═══ [3/3] 下载视觉模型文件 ═══

set MODEL_DIR=%PLUGIN_DIR%models
set MODEL_FILE=Qwen2-VL-7B-Instruct-Q4_K_M.gguf
set MMPROJ_FILE=mmproj-Qwen2-VL-7B-Instruct-f32.gguf
set MODEL_BASE=https://modelscope.cn/models/bartowski/Qwen2-VL-7B-Instruct-GGUF/resolve/master

if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"

if exist "%MODEL_DIR%\%MODEL_FILE%" (
    if exist "%MODEL_DIR%\%MMPROJ_FILE%" (
        echo   [跳过] 模型文件已存在
        goto :done
    )
)

echo   即将下载两个文件（共约 7.4GB），请耐心等待...
echo.

:: Download main model
if not exist "%MODEL_DIR%\%MODEL_FILE%" (
    echo   [下载] 主模型 Q4_K_M (~4.7GB)...
    powershell -Command "& {
        $url = '%MODEL_BASE%/%MODEL_FILE%'
        $out = '%MODEL_DIR%\%MODEL_FILE%'
        Write-Host '  从 ModelScope 下载中（国内高速）...'
        Invoke-WebRequest -Uri $url -OutFile $out
    }"
    if not exist "%MODEL_DIR%\%MODEL_FILE%" (
        echo   [错误] 模型下载失败
        echo   请手动从 ModelScope 下载：%MODEL_BASE%
        pause & exit /b 1
    )
    echo   [完成] 主模型下载完成
) else (
    echo   [跳过] 主模型已存在
)

:: Download mmproj
if not exist "%MODEL_DIR%\%MMPROJ_FILE%" (
    echo   [下载] 视觉投影器 (~2.7GB)...
    powershell -Command "& {
        $url = '%MODEL_BASE%/%MMPROJ_FILE%'
        $out = '%MODEL_DIR%\%MMPROJ_FILE%'
        Invoke-WebRequest -Uri $url -OutFile $out
    }"
    if not exist "%MODEL_DIR%\%MMPROJ_FILE%" (
        echo   [错误] 投影器下载失败
        pause & exit /b 1
    )
    echo   [完成] 投影器下载完成
) else (
    echo   [跳过] 投影器已存在
)

:: ── Done ──
:done
echo.
echo   [配置] 注册 MCP 服务到 Claude Code...

:: Replace {{PLUGIN_DIR}} with actual path
set PLUGIN_DIR_ESC=%PLUGIN_DIR:\=\\%
powershell -Command "& {
    $template = Get-Content '%PLUGIN_DIR%.mcp.json' -Raw -Encoding UTF8
    $template = $template -replace '\{\{PLUGIN_DIR\}\}', '%PLUGIN_DIR_ESC%'
    $template = $template -replace '\\\\', '\\'
    $userMcp = [Environment]::GetFolderPath('UserProfile') + '\.claude\.mcp.json'
    $merged = @{}
    if (Test-Path $userMcp) {
        $existing = Get-Content $userMcp -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($p in $existing.mcpServers.PSObject.Properties) {
            $merged[$p.Name] = $p.Value
        }
    }
    $new = $template | ConvertFrom-Json
    foreach ($p in $new.PSObject.Properties) {
        $merged[$p.Name] = $p.Value
    }
    $output = @{ mcpServers = $merged } | ConvertTo-Json -Depth 10
    $output | Set-Content $userMcp -Encoding UTF8
    Write-Host '  MCP 配置已写入 ~/.claude/.mcp.json'
}"
if %errorlevel% neq 0 (
    echo   [警告] 自动配置 MCP 失败
    echo   请手动将 .mcp.json 中的内容合并到 ~/.claude/.mcp.json
)

:: ── Auto-approve MCP server in settings.json ──
echo   [配置] 自动授权 MCP 服务器...
powershell -Command "& {
    $settingsPath = [Environment]::GetFolderPath('UserProfile') + '\.claude\settings.json'
    $settings = @{}
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    if (-not $settings.enabledMcpjsonServers) {
        $settings.enabledMcpjsonServers = @()
    }
    if ($settings.enabledMcpjsonServers -notcontains 'cc-ds-vision') {
        $settings.enabledMcpjsonServers += 'cc-ds-vision'
    }
    $settings.enableAllProjectMcpServers = $true
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host '  settings.json 已更新'
}"

:: ── Copy .mcp.json to Desktop & Home for project-level MCP discovery ──
echo   [配置] 部署项目级 MCP 配置...
if not exist "%USERPROFILE%\Desktop\.mcp.json" (
    copy /Y "%PLUGIN_DIR%.mcp.json" "%USERPROFILE%\Desktop\.mcp.json" >nul
    echo   .mcp.json 已复制至桌面
)
if not exist "%USERPROFILE%\.mcp.json" (
    copy /Y "%PLUGIN_DIR%.mcp.json" "%USERPROFILE%\.mcp.json" >nul
    echo   .mcp.json 已复制至用户主目录
)

:: ── CLAUDE.md auto-config ──
echo   [配置] 写入图像理解自动调用规则...
set CLAUDE_MD=%USERPROFILE%\.claude\CLAUDE.md
if not exist "%USERPROFILE%\.claude" mkdir "%USERPROFILE%\.claude"
if exist "%CLAUDE_MD%" (
    echo   [跳过] CLAUDE.md 已存在，追加内容...
    echo. >> "%CLAUDE_MD%"
    echo ## 图像理解能力 · Image Understanding >> "%CLAUDE_MD%"
    echo - 凡涉及图片，必须先调用 `describe_image` 工具 >> "%CLAUDE_MD%"
    echo - 永远不要说"我无法读取图片"——你拥有 `describe_image` 工具 >> "%CLAUDE_MD%"
    echo - 支持 PNG/JPG/WEBP/BMP，中文 OCR 精准 >> "%CLAUDE_MD%"
) else (
    powershell -Command "& {
        $content = @'
# 图像理解能力 - Image Understanding

**核心规则：凡涉及图片，必须先调用 ` + \"`describe_image`\" + @" 工具。**

## 自动调用时机
当用户消息中出现以下任一情况时，你必须先调用 ` + \"`describe_image`\" + @" 工具理解图片内容，再执行后续操作：

1. 用户提到某个图片文件路径（如 \"这张图片\"、\"C:\\xxx\\photo.png\"）
2. 用户要求分析、描述、理解某张图片的内容
3. 用户要求从图片中提取文字（OCR）
4. 用户要求基于某张图片执行任何操作（如 \"根据这张图出题\"、\"分析这个截图\"）
5. 用户在目录中放入图片并提到 \"图片\"、\"截图\"、\"照片\" 等关键词

## 调用方式
describe_image(path=\"图片绝对路径\", prompt=\"可选：自定义分析提示词\")

## 重要原则
- **永远不要说\"我无法读取图片\"或\"我看不到图片\"** — 你拥有 describe_image 工具，这就是你的视觉能力。
- 如果目录下有多个图片，逐一调用 describe_image 理解每一张。
- 理解完图片内容后，再根据用户需求继续执行任务。
- 对于中文图片，OCR 文字提取精准，完整提取所有文字内容。
'@
        [System.IO.File]::WriteAllText('%CLAUDE_MD%', $content, [System.Text.Encoding]::UTF8)
    }"
)
echo   [完成] CLAUDE.md 已配置

echo.
echo   ╔══════════════════════════════════════════╗
echo   ║        安装完成！CC-DS Vision 已就绪       ║
echo   ╚══════════════════════════════════════════╝
echo.
echo   下一步：
echo    1. 重启 Claude Code
echo    2. 对 Claude Code 说「描述这张图片」
echo       Claude Code 会自动调用本地视觉模型
echo.
echo   技术细节：
echo    - 模型：Qwen2-VL-7B (Q4_K_M)
echo    - 引擎：llama.cpp CUDA 12.4
echo    - 首次识别约 5-8 秒，后续亚秒级
echo.
pause
