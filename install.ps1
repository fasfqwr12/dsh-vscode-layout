# ============================================================
#  dsh-vscode-layout 一键安装脚本（Windows）
#  用法：右键 install.ps1 → 使用 PowerShell 运行
#       或: powershell -ExecutionPolicy Bypass -File install.ps1
#  自动完成: 装插件 → 打补丁 → 写 cordis.patch.yml
# ============================================================
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host '===== dsh-vscode-layout 安装器 ====='

# 0) 前置检查
$dshCmd = Get-Command dsh -ErrorAction SilentlyContinue
if (-not $dshCmd) {
    Write-Host '未找到 dsh 命令，请先安装: npm i -g @deepseek-ai/dsh' -ForegroundColor Yellow
    exit 1
}

# 1) 定位全局 dsh 包目录（Windows 默认 %APPDATA%\npm\node_modules）
$globalRoot = Join-Path $env:APPDATA 'npm\node_modules'
$dshPkg = Join-Path $globalRoot '@deepseek-ai\dsh'
if (-not (Test-Path $dshPkg)) {
    Write-Host "未找到全局 dsh 包目录: $dshPkg" -ForegroundColor Yellow
    exit 1
}

# 2) 安装自研插件
$profilesNode = Join-Path $env:USERPROFILE '.dsh\profiles\node_modules\@anoslide'
New-Item -ItemType Directory -Path $profilesNode -Force | Out-Null
Copy-Item (Join-Path $here 'plugins\*') $profilesNode -Recurse -Force
Write-Host "[1/3] 插件已安装 -> $profilesNode"

# 3) 打官方包补丁
$patchSrc = Join-Path $here 'patches\node_modules\@deepseek-ai'
$patchDst = Join-Path $dshPkg 'node_modules\@deepseek-ai'
if (Test-Path $patchSrc) {
    Copy-Item (Join-Path $patchSrc '*') $patchDst -Recurse -Force
    Write-Host "[2/3] 补丁已应用 -> $patchDst"
} else {
    Write-Host '[2/3] 未找到 patches 目录，跳过' -ForegroundColor Yellow
}

# 4) 写入 cordis.patch.yml（已存在则不覆盖，避免冲掉已有配置）
$targetCfg = Join-Path $env:USERPROFILE '.dsh\profiles\web\cordis.patch.yml'
if (Test-Path $targetCfg) {
    Write-Host '[3/3] 检测到已有 cordis.patch.yml，未覆盖。' -ForegroundColor Yellow
    Write-Host '      请手动把仓库里 cordis.patch.yml 的 vscode-host-files 段合并进去（见 README）。'
} else {
    New-Item -ItemType Directory -Path (Split-Path $targetCfg) -Force | Out-Null
    Copy-Item (Join-Path $here 'cordis.patch.yml') $targetCfg -Force
    Write-Host "[3/3] 配置已写入 -> $targetCfg"
}

Write-Host ''
Write-Host '===== 安装完成！启动方式 ====='
Write-Host '  1) 终端运行: dsh web'
Write-Host '  2) 浏览器打开 http://127.0.0.1:3080'
Write-Host ''
Write-Host '提示:'
Write-Host '  - 模板配置里的 MCP 段落（qwen-vision/github 等）是占位符，'
Write-Host '    不需要 MCP 可直接删掉对应段落；需要则填入自己的密钥。'
Write-Host '  - 补丁按当前 dsh 版本制作，若你的版本不同可能部分失效，'
Write-Host '    但核心布局（自研插件）不受影响。'
