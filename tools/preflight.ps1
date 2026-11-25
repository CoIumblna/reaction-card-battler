# 详细自检（主套之外的那一半验收）—— 教练每轮手工跑的检查，固化成脚本。
#
# 用法：
#   tools\preflight.bat                      双击或命令行
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\preflight.ps1
#   由 run_tests.bat 自动调用（所以平时只跑 run_tests.bat 就够了）
#
# 它做八件事（run_tests.bat / check.ps1 不做的部分）：
#   1. 待启用基线 tests/pending —— 每个文件 项数 / 红 / SCRIPT ERROR（报告，不算失败）
#   2. 数据校验 tools/validate_data.gd —— 必须 PASS
#   3. 旧字段残留 has_acted —— M3.1 启用后必须 0 命中
#   4. EXPECTED_CHECKS 声明完整性 —— 每个测试文件都必须声明
#   5. 单位卡 unit_class 覆盖率 —— cards.json 里单位卡必须都标了兵科
#   6. 平衡冒烟 balance_sim 100 场 —— 胜率 45–60%、平均回合 8–20、RUNNING 0
#   7. 脚本编码 —— *.bat 必须 CRLF + 纯 ASCII；*.ps1 有中文必须 UTF-8 BOM
#   8. 工作区噪音 —— statuses.json 的行尾换行假 diff
#
# 退出码：0 = 全部通过；1 = 有失败项（报告里的 [FAIL]）

param(
    [string]$Godot = "",
    [string]$ProjectRoot = "",
    [int]$BalanceGames = 100
)

$ErrorActionPreference = "Continue"

if ($Godot -eq "") {
    if ($env:GODOT) { $Godot = $env:GODOT }
    else { $Godot = Join-Path $PSScriptRoot "..\..\..\..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
}
if ($ProjectRoot -eq "") {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if (-not (Test-Path $Godot)) {
    Write-Host "[错误] 找不到 Godot：$Godot" -ForegroundColor Red
    Write-Host "       设置环境变量 GODOT，或传 -Godot <路径>。" -ForegroundColor Yellow
    exit 2
}

$fails = 0
$warns = 0

function Say-Fail { param([string]$Msg)
    Write-Host ("  [FAIL] " + $Msg) -ForegroundColor Red
    $script:fails++
}
function Say-Warn { param([string]$Msg)
    Write-Host ("  [warn] " + $Msg) -ForegroundColor Yellow
    $script:warns++
}
function Say-Ok { param([string]$Msg)
    Write-Host ("  [ok]   " + $Msg) -ForegroundColor Green
}
function Say-Info { param([string]$Msg)
    Write-Host ("  " + $Msg) -ForegroundColor DarkGray
}

Write-Host "========== 详细自检（主套之外） =========="
Write-Host "项目：$ProjectRoot"
Write-Host "Godot：$Godot"
Write-Host ""

# ---------------------------------------------------------------- 1. 待启用基线
Write-Host "[1] 待启用基线 tests/pending（报告用，红是正常的）"
$pendingDir = Join-Path $ProjectRoot "tests\pending"
$pendingFiles = @()
if (Test-Path $pendingDir) {
    $pendingFiles = @(Get-ChildItem $pendingDir -Filter "*_test.gd" -File | Sort-Object Name)
}
if ($pendingFiles.Count -eq 0) {
    Say-Info "tests/pending 下没有测试文件（全部已启用）"
} else {
    Write-Host ("  {0,-24} {1,7} {2,7} {3,14}  {4}" -f "文件", "项数", "红", "SCRIPT ERROR", "状态")
    Write-Host ("  " + ("-" * 70))
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
            Write-Host ("  {0,-24} {1,7} {2,7} {3,14}  {4}" -f $pname, $pc, $pfl, $perr, "就绪→可移入 tests/") -ForegroundColor Green
        } else {
            Write-Host ("  {0,-24} {1,7} {2,7} {3,14}  {4}" -f $pname, $pc, $pfl, $perr, "待实现") -ForegroundColor Yellow
        }
    }
}

# ---------------------------------------------------------------- 2. 数据校验
Write-Host ""
Write-Host "[2] 数据校验 tools/validate_data.gd"
$validatePath = Join-Path $ProjectRoot "tools\validate_data.gd"
if (-not (Test-Path $validatePath)) {
    Say-Warn "没有 tools/validate_data.gd，跳过"
} else {
    $vout = & $Godot --headless --path $ProjectRoot --script res://tools/validate_data.gd 2>&1 | Out-String
    $vpass = $vout.Contains("PASS") -and (-not $vout.Contains("[ERROR]"))
    if ($vpass) {
        Say-Ok "PASS（cards/reactions/statuses/elements 合法）"
    } else {
        Say-Fail "validate_data FAIL —— 改 data/ 后必须过；逐条错误用下面这条看："
        Say-Info "& `$g --headless --path . --script res://tools/validate_data.gd"
    }
}

# ---------------------------------------------------------------- 3. 旧字段残留
Write-Host ""
Write-Host "[3] 旧字段残留 has_acted"
$m31Enabled = Test-Path (Join-Path $ProjectRoot "tests\keywords_test.gd")
$srcDir = Join-Path $ProjectRoot "src"
$hits = @()
if (Test-Path $srcDir) {
    foreach ($f in (Get-ChildItem $srcDir -Filter "*.gd" -Recurse -File)) {
        $n = 0
        foreach ($line in (Get-Content $f.FullName)) {
            $n++
            if ($line -match "has_acted") { $hits += ("{0}:{1}" -f $f.Name, $n) }
        }
    }
}
if ($hits.Count -eq 0) {
    Say-Ok "src/ 里没有 has_acted（M3.1 已拆成 has_moved / has_attacked）"
} elseif ($m31Enabled) {
    Say-Fail ("keywords_test 已启用，src/ 里仍有 {0} 处 has_acted 残留：{1}" -f $hits.Count, ($hits -join "、"))
    Say-Info "残影不会报错但会静默失效（GDScript 动态属性），主套红的时候极难查"
} else {
    Say-Info ("还有 {0} 处 has_acted（M3.1 未启用，属正常）：{1}" -f $hits.Count, ($hits -join "、"))
}

# ---------------------------------------------------------------- 4. EXPECTED_CHECKS
Write-Host ""
Write-Host "[4] EXPECTED_CHECKS 声明完整性"
$testFiles = @(Get-ChildItem (Join-Path $ProjectRoot "tests") -Filter "*_test.gd" -File | Sort-Object Name)
$missing = @()
foreach ($f in $testFiles) {
    $t = Get-Content $f.FullName -Raw
    if ($t -notmatch "const EXPECTED_CHECKS := (\d+)") { $missing += $f.Name }
}
if ($missing.Count -eq 0) {
    Say-Ok ("{0} 个测试文件都声明了 EXPECTED_CHECKS" -f $testFiles.Count)
} else {
    Say-Fail ("没声明 EXPECTED_CHECKS：{0} —— 项数漏跑时会假绿" -f ($missing -join "、"))
}

# ---------------------------------------------------------------- 5. 兵科覆盖
Write-Host ""
Write-Host "[5] 单位卡 unit_class 覆盖率（cards.json）"
$cardsPath = Join-Path $ProjectRoot "data\tables\cards.json"
if (-not (Test-Path $cardsPath)) {
    Say-Warn "没有 data/tables/cards.json，跳过"
} else {
    try {
        $cardsDoc = Get-Content $cardsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Say-Fail "cards.json 解析失败：$($_.Exception.Message)"
        $cardsDoc = $null
    }
    if ($cardsDoc -ne $null) {
        $unitCards = @($cardsDoc.cards | Where-Object { $_.type -eq "unit" })
        $noClass = @($unitCards | Where-Object { -not $_.unit_class -or $_.unit_class -eq "" })
        $classes = @($unitCards | Where-Object { $_.unit_class } | ForEach-Object { $_.unit_class } | Sort-Object -Unique)
        if ($unitCards.Count -eq 0) {
            Say-Info "cards.json 里没有单位卡"
        } elseif ($noClass.Count -eq 0) {
            Say-Ok ("{0} 张单位卡都标了兵科（{1}）" -f $unitCards.Count, ($classes -join "、"))
        } else {
            Say-Warn ("{0}/{1} 张单位卡没标 unit_class：{2}" -f $noClass.Count, $unitCards.Count, (($noClass | ForEach-Object { $_.id }) -join "、"))
            Say-Info "M3.1 测试自己造卡不受影响；M3.3/M3.4 落地前应补齐（不允许空兵科进真实卡池）"
        }
    }
}

# ---------------------------------------------------------------- 6. 平衡冒烟
Write-Host ""
Write-Host ("[6] 平衡冒烟 balance_sim {0} 场" -f $BalanceGames)
$simPath = Join-Path $ProjectRoot "tools\balance_sim.gd"
if (-not (Test-Path $simPath)) {
    Say-Warn "没有 tools/balance_sim.gd，跳过"
} else {
    $argsSim = @("--headless", "--path", $ProjectRoot, "--script", "res://tools/balance_sim.gd", "--", "--games", "$BalanceGames")
    $simOut = & $Godot @argsSim 2>&1 | Out-String
    $mWin = [regex]::Match($simOut, "玩家胜率 ([\d\.]+)%")
    $mTurn = [regex]::Match($simOut, "平均回合 ([\d\.]+)")
    $mRun = [regex]::Match($simOut, "超时/RUNNING ([\d\.]+)%")
    if (-not ($mWin.Success -and $mTurn.Success)) {
        Say-Fail "balance_sim 没跑出结果（可能对局卡死）；直接跑它看输出"
        Say-Info "& `$g --headless --path . --script res://tools/balance_sim.gd -- --games $BalanceGames"
    } else {
        $winrate = [double]$mWin.Groups[1].Value
        $turns = [double]$mTurn.Groups[1].Value
        $runPct = 0.0
        if ($mRun.Success) { $runPct = [double]$mRun.Groups[1].Value }
        $okWin = ($winrate -ge 45.0) -and ($winrate -le 60.0)
        $okTurn = ($turns -ge 8.0) -and ($turns -le 20.0)
        $okRun = ($runPct -lt 1.0)
        if ($okWin -and $okTurn -and $okRun) {
            Say-Ok ("胜率 {0}%（目标 45–60%）、平均 {1} 回合（目标 8–20）、RUNNING {2}%" -f $winrate, $turns, $runPct)
        } else {
            $bad = @()
            if (-not $okWin) { $bad += "胜率 $winrate% 出区间 45–60%" }
            if (-not $okTurn) { $bad += "平均 $turns 回合出区间 8–20" }
            if (-not $okRun) { $bad += "RUNNING $runPct% ≥ 1%" }
            Say-Warn ("平衡指标出界（M3.8 才调参，本阶段只做记录）：" + ($bad -join "；"))
            Say-Info "平衡基线见 docs/balance-report.md；调参归 M3.8，本块不动数值"
        }
    }
}

# ---------------------------------------------------------------- 7. 脚本编码
Write-Host ""
Write-Host "[7] 脚本编码（.bat = CRLF + 纯 ASCII；.ps1 有中文 = UTF-8 BOM）"
$scriptFiles = @()
$scriptFiles += @(Get-ChildItem $ProjectRoot -Filter "*.bat" -File -ErrorAction SilentlyContinue)
$scriptFiles += @(Get-ChildItem (Join-Path $ProjectRoot "tools") -Filter "*.bat" -File -ErrorAction SilentlyContinue)
$scriptFiles += @(Get-ChildItem (Join-Path $ProjectRoot "tools") -Filter "*.ps1" -File -ErrorAction SilentlyContinue)
$encBad = @()
foreach ($sf in $scriptFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($sf.FullName)
    if ($sf.Extension -eq ".bat") {
        $text = [System.Text.Encoding]::ASCII.GetString($bytes)
        $hasNonAscii = $false
        foreach ($b in $bytes) { if ($b -gt 127) { $hasNonAscii = $true; break } }
        $hasCrlf = $text.Contains("`r`n")
        $hasLoneLf = ($text -replace "`r`n", "") -match "(?<!`r)`n"
        if ($hasNonAscii) { $encBad += ("{0}（含非 ASCII 字符，cmd 会乱码）" -f $sf.Name) }
        if (-not $hasCrlf) { $encBad += ("{0}（不是 CRLF）" -f $sf.Name) }
        elseif ($hasLoneLf) { $encBad += ("{0}（混有裸 LF 行）" -f $sf.Name) }
    } else {
        $hasBom = ($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
        $nonAscii = $false
        foreach ($b in $bytes) { if ($b -gt 127) { $nonAscii = $true; break } }
        if ($nonAscii -and -not $hasBom) { $encBad += ("{0}（有中文但没有 UTF-8 BOM，PowerShell 5.1 会乱码）" -f $sf.Name) }
    }
}
if ($encBad.Count -eq 0) {
    Say-Ok ("{0} 个脚本编码都合规" -f $scriptFiles.Count)
} else {
    foreach ($e in $encBad) { Say-Warn $e }
    Say-Info "修法：.bat 用 CRLF + 纯 ASCII；.ps1 存成 UTF-8 with BOM"
}

# ---------------------------------------------------------------- 8. 工作区噪音
Write-Host ""
Write-Host "[8] 工作区噪音（编辑器自动改的行尾换行）"
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd -or -not (Test-Path (Join-Path $ProjectRoot ".git"))) {
    Say-Info "不是 git 仓库或没有 git，跳过"
} else {
    $noiseTargets = @("data/tables/statuses.json", "data/tables/cards.json", "data/tables/elements.json", "data/tables/reactions.json")
    $noise = @()
    foreach ($t in $noiseTargets) {
        $d = & git -C $ProjectRoot diff --numstat -- $t 2>$null
        if (-not $d) { continue }
        $parts = ($d -split "\s+")
        if ($parts.Count -ge 3 -and $parts[0] -eq "1" -and $parts[1] -eq "1") {
            $detail = & git -C $ProjectRoot diff -- $t 2>$null | Out-String
            if ($detail -match "No newline at end of file") { $noise += $t }
        }
    }
    if ($noise.Count -eq 0) {
        Say-Ok "data/tables/*.json 没有行尾换行假 diff"
    } else {
        Say-Warn ("纯行尾换行 diff：" + ($noise -join "、"))
        Say-Info ("还原：git checkout -- " + ($noise -join " "))
    }
    $dirty = @(& git -C $ProjectRoot status --porcelain 2>$null)
    if ($dirty.Count -eq 0) {
        Say-Ok "工作区干净"
    } else {
        Say-Info ("工作区有 {0} 项改动（提交前确认都是本块要的）：" -f $dirty.Count)
        foreach ($line in $dirty) { Say-Info ("    " + $line) }
    }
}

# ---------------------------------------------------------------- 结论
Write-Host ""
Write-Host ("------------------------------")
if ($fails -eq 0) {
    Write-Host ("[详细自检] PASS（{0} 条提醒）" -f $warns) -ForegroundColor Green
    exit 0
}
Write-Host ("[详细自检] FAIL（{0} 条失败、{1} 条提醒）" -f $fails, $warns) -ForegroundColor Red
exit 1
