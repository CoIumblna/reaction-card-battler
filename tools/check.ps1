# 验收工具：跑全套测试 + 打印进度表 + 任务检查点
#
# 用法（不用 agent 也能跑）：
#   tools\check.bat                       双击或命令行
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\check.ps1
#
# 它做四件事：
#   1. --import 一次
#   2. 跑 tests/*_test.gd（自动发现；tests/pending/ 不算）
#   3. 打印每个文件的 项数 / 失败 / SCRIPT ERROR
#   4. 打印 E15、C8 的检查点（哪些已经绿了）

param(
    [string]$Godot = "C:\Users\LD\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
    [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Continue"

if ($ProjectRoot -eq "") {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}
if (-not (Test-Path $Godot)) {
    Write-Host "[错误] 找不到 Godot：$Godot" -ForegroundColor Red
    Write-Host "      改 tools\check.ps1 顶部的 -Godot 参数，或改 run_tests.bat 第 4 行。" -ForegroundColor Yellow
    exit 2
}

Write-Host "项目：$ProjectRoot"
Write-Host "Godot：$Godot"
Write-Host ""
Write-Host "[import] ..." -NoNewline
& $Godot --headless --path $ProjectRoot --import > $null 2>&1
Write-Host " done"

$files = Get-ChildItem (Join-Path $ProjectRoot "tests") -Filter "*_test.gd" -File | Sort-Object Name
if ($files.Count -eq 0) {
    Write-Host "[错误] tests\ 下没有 *_test.gd" -ForegroundColor Red
    exit 2
}

$totalChecks = 0
$totalFailed = 0
$totalScriptErrors = 0
$redFiles = @()
$outputs = @{}

Write-Host ""
Write-Host ("{0,-26} {1,8} {2,8} {3,12}  {4}" -f "文件", "项数", "失败", "SCRIPT ERROR", "结果")
Write-Host ("-" * 76)

foreach ($f in $files) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $raw = & $Godot --headless --path $ProjectRoot --script ("res://tests/" + $name + ".gd") 2>&1
    $text = ($raw | Out-String)
    $outputs[$name] = $text

    $checks = 0
    $failed = 0
    $m = [regex]::Match($text, "共 (\d+) 项检查，失败 (\d+) 项")
    if ($m.Success) {
        $checks = [int]$m.Groups[1].Value
        $failed = [int]$m.Groups[2].Value
    } else {
        $failed = 1
    }
    $scriptErrors = ([regex]::Matches($text, "SCRIPT ERROR")).Count
    $hasPass = $text.Contains("PASS")

    $totalChecks += $checks
    $totalFailed += $failed
    $totalScriptErrors += $scriptErrors

    $verdict = "PASS"
    if ($failed -gt 0 -or -not $hasPass -or $scriptErrors -gt 0) {
        $verdict = "FAIL"
        $redFiles += $name
    }
    Write-Host ("{0,-26} {1,8} {2,8} {3,12}  {4}" -f $name, $checks, $failed, $scriptErrors, $verdict)
}

Write-Host ("-" * 76)
Write-Host ("合计：{0} 项检查，{1} 条失败，{2} 条 SCRIPT ERROR" -f $totalChecks, $totalFailed, $totalScriptErrors)

# ---------------------------------------------------------------- 检查点
function Show-Checkpoints {
    param([string]$Title, [string]$File, $Points)
    if (-not $outputs.ContainsKey($File)) {
        Write-Host ""
        Write-Host ("[{0}] {1}（测试文件未启用：{2}）" -f $Title, $Title, $File) -ForegroundColor DarkYellow
        return
    }
    Write-Host ""
    Write-Host ("[{0}] 检查点（{1}）" -f $Title, $File)
    $text = $outputs[$File]
    $lines = $text -split "`n"
    foreach ($p in $Points) {
        $label = $p[0]
        $needle = $p[1]
        $ok = $false
        foreach ($line in $lines) {
            if ($line.Contains("[ok]") -and $line.Contains($needle)) {
                $ok = $true
                break
            }
        }
        if ($ok) {
            Write-Host ("  [完成] {0}" -f $label) -ForegroundColor Green
        } else {
            Write-Host ("  [ 待做] {0}" -f $label) -ForegroundColor Yellow
        }
    }
}

$e15 = @(
    @("敌方资源与手牌（牌库复制 / 起手 5 张）", "敌方起手 5 张"),
    @("敌方 Kredit 每回合 +1、每回合抽 1", "敌方 Kredit 每回合 +1"),
    @("敌方会部署（owner = enemy）", "敌方部署的单位 owner = enemy"),
    @("敌方会推进前线（不挪 HQ）", "敌方把支援线的单位推进了前线"),
    @("敌方会攻击（够得着 HQ 先打 HQ）", "敌方前线单位打了玩家 HQ"),
    @("敌方 has_acted 每个敌方回合清零", "敌方单位下一回合能再次攻击"),
    @("自动对局能分出胜负（WIN/LOSE）", "自动对局能分出胜负")
)
$c8 = @(
    @("Battle 加载 statuses.json（status_table）", "setup() 加载了 statuses.json"),
    @("dot：回合开始掉血（burn）", "燃烧掉 1 血"),
    @("disable：冻结的单位不能行动", "冻结的单位本回合被标记为不能行动"),
    @("反应挂状态（感电 → shock）", "感电反应把 shock 挂到目标身上")
)

Show-Checkpoints -Title "E15 敌方 AI" -File "battle_m2_test" -Points $e15
Show-Checkpoints -Title "C8 状态生效" -File "status_test" -Points $c8

# ---------------------------------------------------------------- 待启用验收（tests/pending）
$pendingDir = Join-Path $ProjectRoot "tests\pending"
$pendingFiles = @()
if (Test-Path $pendingDir) {
    $pendingFiles = @(Get-ChildItem $pendingDir -Filter "*_test.gd" -File | Sort-Object Name)
}
if ($pendingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "[待启用验收] tests/pending（不参与 CI / run_tests，只做基线报告）"
    foreach ($pf in $pendingFiles) {
        $pname = [System.IO.Path]::GetFileNameWithoutExtension($pf.Name)
        $pout = & $Godot --headless --path $ProjectRoot --script ("res://tests/pending/" + $pname + ".gd") 2>&1 | Out-String
        $pm = [regex]::Match($pout, "共 (\d+) 项检查，失败 (\d+) 项")
        $pc = 0
        $pfl = -1
        if ($pm.Success) {
            $pc = [int]$pm.Groups[1].Value
            $pfl = [int]$pm.Groups[2].Value
        }
        $perr = ([regex]::Matches($pout, "SCRIPT ERROR")).Count
        if ($pfl -eq 0 -and $perr -eq 0) {
            Write-Host ("  [就绪] {0}：{1} 项全绿 → 可以移到 tests/ 启用" -f $pname, $pc) -ForegroundColor Green
        } else {
            Write-Host ("  [待实现] {0}：{1} 项检查 / {2} 红 / {3} SCRIPT ERROR" -f $pname, $pc, $pfl, $perr) -ForegroundColor Yellow
        }
    }
}

# ---------------------------------------------------------------- 数据校验（M3.5）
$validatePath = Join-Path $ProjectRoot "tools\validate_data.gd"
if (Test-Path $validatePath) {
    $vout = & $Godot --headless --path $ProjectRoot --script res://tools/validate_data.gd 2>&1 | Out-String
    $vpass = $vout.Contains("PASS") -and (-not $vout.Contains("[ERROR]"))
    Write-Host ""
    if ($vpass) {
        Write-Host "[数据校验] validate_data.gd：PASS（cards/reactions/statuses/elements 合法）" -ForegroundColor Green
    } else {
        Write-Host "[数据校验] validate_data.gd：FAIL —— 跑它看逐条错误（改 data/ 后必须过）" -ForegroundColor Red
    }
}

# ---------------------------------------------------------------- 结论
Write-Host ""
$statusEnabled = $outputs.ContainsKey("status_test")
$target = 308
if ($statusEnabled) { $target = 320 }

if ($totalFailed -eq 0 -and $totalScriptErrors -eq 0 -and $redFiles.Count -eq 0) {
    Write-Host ("===== ALL GREEN：{0}/{0} =====" -f $target) -ForegroundColor Green
    if ($pendingFiles.Count -gt 0) {
        Write-Host "待启用验收在 tests/pending：实现在 docs §25（E14）/ §26（E7），全绿后移入 tests/ 再提交。"
    }
    Write-Host "可以提交了：git add -A; git commit -F <消息文件>"
    exit 0
}

Write-Host ("目标：{0}/{0}（当前 {1} 项，{2} 条失败，红文件：{3}）" -f $target, $totalChecks, $totalFailed, ($redFiles -join "、")) -ForegroundColor Yellow
Write-Host ""
Write-Host "下一步："
if ($redFiles -contains "battle_m2_test") {
    Write-Host "  - battle_m2_test 还有红 → 继续 E15（docs §23）：_enemy_ai() 三段 → run_auto() 重写"
}
if ($redFiles -contains "status_test") {
    Write-Host "  - status_test 有红 → 做 C8（docs §24）：status_table + 回合开始四步 + 反应挂状态"
}
$others = $redFiles | Where-Object { $_ -ne "battle_m2_test" -and $_ -ne "status_test" }
if ($others) {
    Write-Host ("  - 其他文件有红（{0}）→ 这是回归，先修；别继续往下写" -f ($others -join "、")) -ForegroundColor Red
}
exit 1
