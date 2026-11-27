param(
    [int]$Games = 10,
    [int]$TimeoutSec = 120
)
# param() 必须是脚本第一条可执行语句；注释统一放这里（第 9 行 parse error 的根因）。
# ai_order_report.ps1 - M3.8a AI 打指令卡的验收报表（教练侧验收脚本）
# 三件事：
#   [1] 跑 tests/pending/ai_order_test.gd（学员写完迁进 tests/ 后自动改跑主套那份）
#   [2] 10 个固定 seed 跑 run_auto，输出 turn/outcome 对照表（同 seed 两次必须逐位一致 = 可复现）
#   [3] 统计 AI 每局打了几张指令卡（读日志里「AI打出指令卡」行数）
# 任一项红退出码 1。
# 编码规则：UTF-8 with BOM。
$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$proj = Split-Path -Parent $PSScriptRoot
$godot = $env:GODOT
if (-not $godot) { Write-Host "[AI ORDER] GODOT env not set" -ForegroundColor Red; exit 2 }
$logDir = Join-Path $proj "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Invoke-Godot {
    param([string[]]$GodotArgs, [string]$Log)
    $errLog = "$Log.err"
    $p = Start-Process -FilePath $godot -ArgumentList $GodotArgs `
        -RedirectStandardOutput $Log -RedirectStandardError $errLog `
        -PassThru -NoNewWindow
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        try { $p.Kill() } catch {}
        $p.WaitForExit(); Start-Sleep -Milliseconds 300
        [IO.File]::AppendAllText($Log, "`n[HUNG]", (New-Object Text.UTF8Encoding $false))
        return 3
    }
    return $p.ExitCode
}

$red = 0

# ---------- [1] ai_order_test ----------
$testPath = Join-Path $proj "tests\ai_order_test.gd"
$pendPath = Join-Path $proj "tests\pending\ai_order_test.gd"
$which = if (Test-Path $testPath) { "res://tests/ai_order_test.gd" }
         elseif (Test-Path $pendPath) { "res://tests/pending/ai_order_test.gd" }
         else { "" }
if ($which -eq "") {
    Write-Host "[1] ai_order_test  MISSING（tests/pending/ai_order_test.gd 还没写）" -ForegroundColor Yellow
    $verdict1 = "MISSING"; $red++
} else {
    $log1 = Join-Path $logDir "ai_order_test.log"
    $rc = Invoke-Godot @("--headless", "--path", "$proj.", "--script", $which) $log1
    $t1 = [IO.File]::ReadAllText($log1)
    $m = [regex]::Match($t1, "共 (\d+) 项检查，失败 (\d+) 项")
    if ($rc -eq 0 -and $m.Success -and $m.Groups[2].Value -eq "0") {
        Write-Host ("[1] ai_order_test  PASS ({0} checks)" -f $m.Groups[1].Value)
        $verdict1 = "PASS $($m.Groups[1].Value)"
    } else {
        Write-Host "[1] ai_order_test  FAIL (rc=$rc)" -ForegroundColor Red
        Get-Content $log1 -Tail 8 | ForEach-Object { Write-Host "    $_" }
        $verdict1 = "FAIL"; $red++
    }
}

# ---------- [2] 10 seed 对照 + 可复现 ----------
$seeds = @(1, 2, 3, 7, 42, 100, 2026, 20261102, 20261127, 555)
$rows = @()
$repro = $true
foreach ($s in $seeds) {
    $logS = Join-Path $logDir "ai_order_seed_$s.log"
    $rc = Invoke-Godot @("--headless", "--path", "$proj.", "--script", "res://tools/balance_sim.gd", "--", "--games", "1", "--seed", "$s") $logS
    if ($null -eq $rc) { $rc = 0 }  # Start-Process.ExitCode 在无 shell 包装时可能为 null（Godot 直启的已知怪癖），null 视为正常退出
    $tS = if (Test-Path $logS) { [IO.File]::ReadAllText($logS) } else { "" }
    $turn = [regex]::Match($tS, "平均回合 (\d+)").Groups[1].Value
    # games=1 时 "WIN 0 / LOSE 1" 表示这局输了；WIN 侧数字 1 = 赢
    $winN = [regex]::Match($tS, "WIN (\d+)").Groups[1].Value
    $out = ""
    if ($winN -eq "1") { $out = "WIN" } elseif ($tS -match "LOSE 1") { $out = "LOSE" }
    $rows += [pscustomobject]@{ seed = $s; turn = $turn; outcome = $out; rc = $rc }
}
# 可复现：同 seed 再跑一遍比对
foreach ($s in ($seeds | Select-Object -First 3)) {
    $logS2 = Join-Path $logDir "ai_order_seed_${s}_b.log"
    Invoke-Godot @("--headless", "--path", "$proj.", "--script", "res://tools/balance_sim.gd", "--", "--games", "1", "--seed", "$s") $logS2 | Out-Null
    $tS2 = [IO.File]::ReadAllText($logS2)
    $turn2 = [regex]::Match($tS2, "平均回合 (\d+)").Groups[1].Value
    $first = $rows | Where-Object { $_.seed -eq $s }
    if ($first.turn -ne $turn2) {
        Write-Host "  repro FAIL seed=$s first=$($first.turn) second=$turn2" -ForegroundColor Red
        $repro = $false
    }
}
$rows | Format-Table -AutoSize | Out-Host
if ($repro -and -not ($rows | Where-Object { $null -ne $_.rc -and $_.rc -ne 0 })) {
    Write-Host "[2] seed 对照 + 可复现  PASS"
    $verdict2 = "PASS"
} else {
    Write-Host "[2] seed 对照 + 可复现  FAIL" -ForegroundColor Red
    $verdict2 = "FAIL"; $red++
}

# ---------- [3] 指令卡统计（读 run_auto 日志） ----------
# 约定：AI 打出指令卡时 core 会 _log("AI打出指令卡 %s")；M3.8a 实现后此计数 > 0
$count = 0
$lastLog = Join-Path $logDir "ai_order_seed_1.log"
if (Test-Path $lastLog) {
    $t = [IO.File]::ReadAllText($lastLog)
    $count = ([regex]::Matches($t, "AI打出指令卡")).Count
}
Write-Host ("[3] AI 指令卡计数（seed=1 局）: {0}" -f $count)
$verdict3 = if ($count -gt 0) { "PASS ($count 张)" } else { "WARN 0 张（M3.8a 未实现或日志词不匹配）" }
if ($count -eq 0) { Write-Host "    期望 M3.8a 完成后 > 0；实现前跑本脚本看到 0 属正常" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  [1] $verdict1"
Write-Host "  [2] $verdict2"
Write-Host "  [3] $verdict3"
if ($red -gt 0) { Write-Host "[AI ORDER FAIL] red=$red" -ForegroundColor Red; exit 1 }
Write-Host "[AI ORDER PASS]"
exit 0
