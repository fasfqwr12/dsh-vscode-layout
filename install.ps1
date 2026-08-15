# ============================================================
#  dsh-vscode-layout 一键安装脚本（Windows）
#  用法：右键 install.ps1 → 使用 PowerShell 运行
#       或: powershell -ExecutionPolicy Bypass -File install.ps1
#  自动完成: 装插件 → 打补丁 → 写 cordis.patch.yml
#  提示：右键运行时窗口会在按回车后关闭；想看到完整日志，
#        请先在已打开的终端里运行 powershell -ExecutionPolicy Bypass -File .\install.ps1
# ============================================================
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host '===== dsh-vscode-layout 安装器 ====='

# 0) 前置检查
$dshCmd = Get-Command dsh -ErrorAction SilentlyContinue
if (-not $dshCmd) {
    Write-Host ''
    Write-Host '未找到 dsh 命令，请先安装: npm i -g @deepseek-ai/dsh' -ForegroundColor Yellow
    Write-Host '安装完 npm 后请【重新打开】这个窗口再运行一次。'
    Read-Host '按回车键关闭'
    exit 1
}

# 1) 定位全局 dsh 包目录（Windows 默认 %APPDATA%\npm\node_modules）
$globalRoot = Join-Path $env:APPDATA 'npm\node_modules'
$dshPkg = Join-Path $globalRoot '@deepseek-ai\dsh'
if (-not (Test-Path $dshPkg)) {
    Write-Host ''
    Write-Host "未找到全局 dsh 包目录: $dshPkg" -ForegroundColor Yellow
    Write-Host '请确认执行过: npm i -g @deepseek-ai/dsh'
    Read-Host '按回车键关闭'
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
Write-Host '  - MCP server 在 dsh 设置面板「MCP 管理」中添加（数据存 ~/.dsh/mcp-servers.json）。'
Write-Host '  - 补丁按当前 dsh 版本制作，若你的版本不同可能部分失效，'
Write-Host '    但核心布局（自研插件）不受影响。'
Write-Host ''
Read-Host '按回车键关闭此窗口'
