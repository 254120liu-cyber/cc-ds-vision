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
