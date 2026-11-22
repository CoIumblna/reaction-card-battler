<#
.SYNOPSIS
    配置本项目的 git（另一台机器 / 另一份 DSH 首次使用）。

.DESCRIPTION
    - 检查 git；不在仓库里时自动 git init（或 -CloneTo 克隆）
    - 配置 user.name / user.email、core.autocrlf=false（避免 LF→CRLF 警告）、
      core.quotepath=false（中文路径正常显示）、core.longpaths、pull.rebase、
      remote origin、safe.directory
    - 检测凭据管理器（Git Credential Manager），没有就提示首次 push 如何登录

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\setup_git.ps1

.EXAMPLE
    # 新机器：克隆到指定目录并配置
    powershell -ExecutionPolicy Bypass -File tools\setup_git.ps1 -CloneTo "D:\projects\reaction-card-battler"

.EXAMPLE
    # 只看会改什么，不实际执行
    powershell -ExecutionPolicy Bypass -File tools\setup_git.ps1 -DryRun
#>
param(
    [string]$Name = "CoIumblna",
    [string]$Email = "awmrzhdlyb2010@163.com",
    [string]$RepoUrl = "https://github.com/CoIumblna/reaction-card-battler.git",
    [string]$CloneTo = "",
    [switch]$Global,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Info([string]$msg) { Write-Host ("[git-setup] " + $msg) }
function Warn([string]$msg) { Write-Host ("[git-setup][警告] " + $msg) -ForegroundColor Yellow }

function Invoke-Git {
    param([string[]]$GitArgs, [switch]$AllowFail)
    $cmd = "git " + ($GitArgs -join " ")
    if ($DryRun) {
        Write-Host ("  [dry-run] " + $cmd)
        return ""
    }
    $out = & git @GitArgs 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -and -not $AllowFail) {
        throw ("命令失败：" + $cmd + "`n" + $out)
    }
    return $out.Trim()
}

# 1) git 可用性
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[错误] 找不到 git。请先安装 Git for Windows：https://git-scm.com/download/win" -ForegroundColor Red
    exit 1
}
Info ("git 版本：" + ((& git --version) -join ""))

# 2) 找到/准备项目目录
if ($CloneTo -ne "") {
    $projectRoot = [IO.Path]::GetFullPath($CloneTo)
    if (-not (Test-Path (Join-Path $projectRoot ".git"))) {
        Info ("目标目录还没有仓库，克隆 " + $RepoUrl + " → " + $projectRoot)
        if (-not $DryRun) {
            $parent = Split-Path $projectRoot -Parent
            if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
            & git clone $RepoUrl $projectRoot
            if ($LASTEXITCODE -ne 0) { Write-Host "[错误] git clone 失败（检查网络/仓库地址/权限）" -ForegroundColor Red; exit 2 }
        }
    } else {
        Info ("目标目录已是仓库：" + $projectRoot)
    }
} else {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if (-not (Test-Path (Join-Path $projectRoot ".git"))) {
    Info ("不是 git 仓库，执行 git init（main 分支）：" + $projectRoot)
    Invoke-Git -GitArgs @("init", "-b", "main") | Out-Null
}
Set-Location $projectRoot
Info ("项目目录：" + $projectRoot)

# 3) 用户身份
Info ("设置身份：" + $Name + " <" + $Email + ">")
Invoke-Git -GitArgs @("config", "user.name", $Name) | Out-Null
Invoke-Git -GitArgs @("config", "user.email", $Email) | Out-Null
if ($Global) {
    Invoke-Git -GitArgs @("config", "--global", "user.name", $Name) | Out-Null
    Invoke-Git -GitArgs @("config", "--global", "user.email", $Email) | Out-Null
    Info "同时写入全局配置（-Global）"
}

# 4) 本仓库配置（避免换行/中文路径/长路径问题）
Info "本仓库配置：autocrlf=false / quotepath=false / longpaths=true / pull.rebase=false"
Invoke-Git -GitArgs @("config", "core.autocrlf", "false") | Out-Null
Invoke-Git -GitArgs @("config", "core.quotepath", "false") | Out-Null
Invoke-Git -GitArgs @("config", "core.longpaths", "true") | Out-Null
Invoke-Git -GitArgs @("config", "pull.rebase", "false") | Out-Null
Invoke-Git -GitArgs @("config", "init.defaultBranch", "main") | Out-Null

# 5) remote origin
$existing = Invoke-Git -GitArgs @("remote", "get-url", "origin") -AllowFail
if ($existing -eq "") {
    Info ("添加 remote origin：" + $RepoUrl)
    Invoke-Git -GitArgs @("remote", "add", "origin", $RepoUrl) | Out-Null
} else {
    Info ("更新 remote origin：" + $existing + " → " + $RepoUrl)
    Invoke-Git -GitArgs @("remote", "set-url", "origin", $RepoUrl) | Out-Null
}

# 6) safe.directory（仓库被复制/换用户时避免 dubious ownership）
$safeList = @()
if (-not $DryRun) { $safeList = @(& git config --global --get-all safe.directory 2>$null) }
if ($safeList -notcontains $projectRoot) {
    Invoke-Git -GitArgs @("config", "--global", "--add", "safe.directory", $projectRoot) | Out-Null
}

# 7) 凭据管理器
$cred = @()
if (-not $DryRun) { $cred = @(& git config --show-origin --get-all credential.helper 2>$null) }
if ($cred.Count -eq 0) {
    $gcm = Get-Command git-credential-manager -ErrorAction SilentlyContinue
    if ($gcm) {
        Info "检测到 Git Credential Manager，写入全局 credential.helper=manager"
        Invoke-Git -GitArgs @("config", "--global", "credential.helper", "manager") | Out-Null
    } else {
        Warn "没有凭据管理器：首次 push 时按提示登录，或使用 GitHub PAT（Personal Access Token）"
    }
} else {
    Info ("已配置凭据管理器：" + (($cred | Select-Object -First 1) -replace '\s+', ' '))
}

# 8) 汇总
Write-Host ""
Write-Host "================ 配置结果 ================"
Write-Host ("git        : " + ((& git --version) -join ""))
Write-Host ("项目        : " + $projectRoot)
Write-Host ("身份        : " + $Name + " <" + $Email + ">")
$remoteNow = if ($DryRun) { $RepoUrl } else { (& git remote get-url origin 2>$null) }
Write-Host ("remote      : " + $remoteNow)
$branchNow = if ($DryRun) { "main" } else { (& git rev-parse --abbrev-ref HEAD 2>$null) }
Write-Host ("当前分支    : " + $branchNow)
Write-Host ""
Write-Host "下一步："
Write-Host "  git pull                 # 拉最新（首次 pull 会和远端合并）"
Write-Host "  tools\check.bat          # 验证：主套应 355/355 ALL GREEN"
Write-Host "  git push                 # 推提交（首次会要求登录 GitHub）"
Write-Host ""
if ($DryRun) { Write-Host "（DryRun：以上改动没有实际执行）" -ForegroundColor Yellow }
exit 0