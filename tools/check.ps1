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
    [string]$Godot = "",
    [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Continue"

# Godot 路径：优先 -Godot 参数 / 环境变量 GODOT，否则用相对本仓库的默认位置（仓库可整体移动）。
if ($Godot -eq "") {
    if ($env:GODOT) { $Godot = $env:GODOT }
    else { $Godot = Join-Path $PSScriptRoot "..\..\..\..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
}
$Godot = [System.IO.Path]::GetFullPath($Godot)

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

# 跑一个 Godot 脚本并取回完整文本。
# 不能写 `& $Godot ... 2>&1 | Out-String`：Godot 的 printerr 会被 PowerShell 包成
# NativeCommandError 记录，行首带上 "Godot_v4.7.2...exe : " 前缀和 CategoryInfo 噪声，
# 导致 [FAIL] 行被截断/重复。改成 Start-Process 直接重定向到临时文件再按 UTF-8 读回。
#
# 必须有墙钟超时：测试里（或被测代码里）有死循环时 Godot 不会崩、也不退出，
# 整个 check 就永远挂着，看起来像工具坏了。超时杀掉并返回带 [HUNG] 的文本，
# 让调用方按「没跑完」报，而不是去解析一个不存在的「共 N 项检查」。
function Invoke-GodotScript {
    param([string]$ScriptPath, [string]$Tag = "cap", [int]$TimeoutSec = 90)
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("dsh_" + $Tag + "_" + [System.Guid]::NewGuid().ToString("N").Substring(0,8) + ".log")
    $err = $tmp + ".err"
    $proc = Start-Process -FilePath $Godot -ArgumentList '--headless','--path',('"' + $ProjectRoot + '"'),'--script',('"' + $ScriptPath + '"') -RedirectStandardOutput $tmp -RedirectStandardError $err -PassThru -NoNewWindow
    if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
        try { $proc.Kill() } catch { }
        try { $proc.WaitForExit() } catch { }
        try { $proc.Dispose() } catch { }
        Start-Sleep -Milliseconds 300
        try { [System.IO.File]::AppendAllText($tmp, [Environment]::NewLine + "[HUNG] godot did not finish within $TimeoutSec s and was killed" + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding $false)) } catch { }
    } else {
        try { $proc.Dispose() } catch { }
    }
    $text = ""
    if (Test-Path $tmp) {
        $text = [System.IO.File]::ReadAllText($tmp, [System.Text.Encoding]::UTF8)
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $err) {
        $etext = [System.IO.File]::ReadAllText($err, [System.Text.Encoding]::UTF8)
        if ($etext.Trim() -ne "") { $text = $text + [Environment]::NewLine + $etext }
        Remove-Item $err -Force -ErrorAction SilentlyContinue
    }
    return $text
}
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
    $text = Invoke-GodotScript -ScriptPath ("res://tests/" + $name + ".gd") -Tag $name
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
    $hung = $text.Contains("[HUNG]")

    $totalChecks += $checks
    $totalFailed += $failed
    $totalScriptErrors += $scriptErrors

    $verdict = "PASS"
    if ($hung) { $verdict = "HUNG" }
    if ($failed -gt 0 -or -not $hasPass -or $scriptErrors -gt 0 -or $hung) {
        if (-not $hung) { $verdict = "FAIL" }
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
    @("敌方行动标志每个敌方回合清零", "敌方单位下一回合能再次攻击"),
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
        $pout = Invoke-GodotScript -ScriptPath ("res://tests/pending/" + $pname + ".gd") -Tag ("p_" + $pname)
        $pm = [regex]::Match($pout, "共 (\d+) 项检查，失败 (\d+) 项")
        $pc = 0
        $pfl = -1
        if ($pm.Success) {
            $pc = [int]$pm.Groups[1].Value
            $pfl = [int]$pm.Groups[2].Value
        }
        $perr = ([regex]::Matches($pout, "SCRIPT ERROR")).Count
        $phung = $pout.Contains("[HUNG]")
        if ($phung) {
            # 没跑完 = 没有任何裁决。"0 红" 在这里毫无意义，必须单独报。
            Write-Host ("  [挂死] {0}：90 s 内没跑完，进程已杀（死循环？）→ 无裁决" -f $pname) -ForegroundColor Red
            $tailLines = ($pout -split "`n") | Where-Object { $_.Trim() -ne "" } | Select-Object -Last 5
            foreach ($tl in $tailLines) {
                Write-Host ("      " + $tl.TrimEnd()) -ForegroundColor DarkRed
            }
        } elseif ($pfl -eq 0 -and $perr -eq 0) {
            Write-Host ("  [就绪] {0}：{1} 项全绿 → 可以移到 tests/ 启用" -f $pname, $pc) -ForegroundColor Green
        } else {
            Write-Host ("  [待实现] {0}：{1} 项检查 / {2} 红 / {3} SCRIPT ERROR" -f $pname, $pc, $pfl, $perr) -ForegroundColor Yellow
            # 把每条失败断言原样打出来：只给「N 红」等于让人去翻日志。
            $fails = [regex]::Matches($pout, "\[FAIL\][^\r\n]*")
            foreach ($fm in $fails) {
                Write-Host ("      " + $fm.Value.Trim()) -ForegroundColor DarkYellow
            }
            if ($perr -gt 0) {
                $serrs = [regex]::Matches($pout, "[^\r\n]*SCRIPT ERROR[^\r\n]*")
                foreach ($sm in $serrs) {
                    Write-Host ("      " + $sm.Value.Trim()) -ForegroundColor DarkRed
                }
            }
        }
    }
}

# ---------------------------------------------------------------- 数据校验（M3.5）
$validatePath = Join-Path $ProjectRoot "tools\validate_data.gd"
if (Test-Path $validatePath) {
    $vout = Invoke-GodotScript -ScriptPath "res://tools/validate_data.gd" -Tag "validate"
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
# 目标项数 = 各启用测试文件里声明的 EXPECTED_CHECKS 之和（改测试只改那个常量即可）
$target = 0
foreach ($f in $files) {
    $fileText = Get-Content $f.FullName -Raw
    $em = [regex]::Match($fileText, "const EXPECTED_CHECKS := (\d+)")
    if ($em.Success) { $target += [int]$em.Groups[1].Value }
}
if ($target -eq 0) { $target = $totalChecks }

if ($totalFailed -eq 0 -and $totalScriptErrors -eq 0 -and $redFiles.Count -eq 0) {
    Write-Host ("===== ALL GREEN：{0}/{0} =====" -f $target) -ForegroundColor Green
    if ($pendingFiles.Count -gt 0) {
        Write-Host "待启用验收在 tests/pending：任务卡见 docs/implementation-tasks.md（当前 M3.4 前置块 = §39），全绿后 git mv 进 tests/ 再提交。"
    }
    Write-Host "可以提交了：git add <逐个路径>; git commit -F <消息文件>（别用 git add -A，会把 WIP 和行尾噪音带进去）"
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
