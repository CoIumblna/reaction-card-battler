# 详细自检（主套之外的那一半验收）—— 教练每轮手工跑的检查，固化成脚本。
#
# 用法：
#   tools\preflight.bat                      双击或命令行
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\preflight.ps1
#   由 run_tests.bat 自动调用（所以平时只跑 run_tests.bat 就够了）
#
# 它做七件事（run_tests.bat / check.ps1 不做的部分）：
#   1. 数据校验 tools/validate_data.gd —— 必须 PASS
#   2. 旧字段残留 has_acted —— M3.1 启用后必须 0 命中
#   3. EXPECTED_CHECKS 声明完整性 —— 每个测试文件都必须声明
#   4. 单位卡 unit_class 覆盖率 —— cards.json 里单位卡必须都标了兵科
#   5. 平衡冒烟 balance_sim 100 场 —— 胜率 45–60%、平均回合 8–20、RUNNING 0
#   6. 脚本编码 —— *.bat 必须 CRLF + 纯 ASCII；*.ps1 有中文必须 UTF-8 BOM
#   7. 工作区噪音 —— statuses.json 的行尾换行假 diff
#
# 注意：tests/pending 的待启用基线不在本脚本里 —— 那一块由 run_tests.bat 的
#       PENDING 段直接打印在主套结果下面（同一个终端一次看完），见 tools/README.md。
#
param(
    [string]$Godot = "",
    [string]$ProjectRoot = "",
    [int]$BalanceGames = 100,
    [switch]$Verbose
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
$oks = 0
$sectionTitle = ""

# 静默原则：一节的标题只在「这节有问题要说」或者 -Verbose 时才打印。
# 全绿时整份报告只剩结论那一行，红的地方立刻跳出来。
function Show-Section {
    if ($sectionTitle -ne "") {
        Write-Host ""
        Write-Host $sectionTitle
        $script:sectionTitle = ""
    }
}

function Say-Fail { param([string]$Msg)
    Show-Section
    Write-Host ("  [FAIL] " + $Msg) -ForegroundColor Red
    $script:fails++
}
function Say-Warn { param([string]$Msg)
    Show-Section
    Write-Host ("  [warn] " + $Msg) -ForegroundColor Yellow
    $script:warns++
}
function Say-Ok { param([string]$Msg)
    $script:oks++
    if ($Verbose) { Show-Section; Write-Host ("  [ok]   " + $Msg) -ForegroundColor Green }
}
function Say-Info { param([string]$Msg)
    if ($Verbose) { Show-Section; Write-Host ("  " + $Msg) -ForegroundColor DarkGray }
}

Write-Host "========== 详细自检（主套之外） =========="
Write-Host "项目：$ProjectRoot"
Write-Host ("Godot：{0}" -f $Godot)


# ---------------------------------------------------------------- 1. 数据校验
$sectionTitle = "[1] 数据校验 tools/validate_data.gd"
$validatePath = Join-Path $ProjectRoot "tools\validate_data.gd"
if (-not (Test-Path $validatePath)) {
    Say-Warn "没有 tools/validate_data.gd，跳过"
} else {
    $vout = & $Godot --headless --path $ProjectRoot --script res://tools/validate_data.gd 2>&1 | Out-String
    $vpass = $vout.Contains("PASS") -and (-not $vout.Contains("[ERROR]"))
    if ($vpass) {
        Say-Ok "PASS（cards/reactions/statuses/elements 合法）"
    } else {
        Say-Fail "validate_data FAIL —— 改 data/ 后必须过。逐条错误："
        Show-Section
        Write-Host $vout
        Write-Host "  手动跑：& `$g --headless --path . --script res://tools/validate_data.gd"
    }
}

# ---------------------------------------------------------------- 3. 旧字段残留
$sectionTitle = "[2] 旧字段残留 has_acted"
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

# ---------------------------------------------------------------- 3. EXPECTED_CHECKS
$sectionTitle = "[3] EXPECTED_CHECKS 声明完整性"
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
$sectionTitle = "[4] 单位卡 unit_class 覆盖率（cards.json）"
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

# ---------------------------------------------------------------- 5. 平衡冒烟
$sectionTitle = ("[5] 平衡冒烟 balance_sim {0} 场" -f $BalanceGames)
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

# ---------------------------------------------------------------- 6. 脚本编码
$sectionTitle = "[6] 脚本编码（.bat = CRLF + 纯 ASCII；.ps1 有中文 = UTF-8 BOM）"
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

# ---------------------------------------------------------------- 7. 工作区噪音
$sectionTitle = "[7] 工作区噪音（编辑器自动改的行尾换行）"
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
        # 未提交改动是常态（学员正在写代码），只在 -Verbose 下列出来，不算问题
        Say-Info ("工作区有 {0} 项改动：" -f $dirty.Count)
        foreach ($line in $dirty) { Say-Info ("    " + $line) }
    }
}

# ---------------------------------------------------------------- 8. 中文字体
$sectionTitle = "[8] 中文字体（M4 界面基座）"
$fontCheck = Join-Path $ProjectRoot "tools\check_font.gd"
if (-not (Test-Path $fontCheck)) {
    Say-Info "还没有 tools/check_font.gd（M4 之前属正常），跳过"
} else {
    $fout = & $Godot --headless --path $ProjectRoot --script res://tools/check_font.gd 2>&1 | Out-String
    if ($fout.Contains("[FONT OK]")) {
        $m = [regex]::Match($fout, "\[FONT OK\]\s*(.+)")
        $fname = if ($m.Success) { $m.Groups[1].Value.Trim() } else { "?" }
        Say-Ok ("中文字形可用，实际字体：{0}" -f $fname)
    } else {
        Say-Fail "中文字形不可用 —— 界面会显示成方块（M4 全部界面都依赖它）"
        Show-Section
        Write-Host $fout
        Say-Info "修法：检查 src/ui/ui_theme.gd 的 FONT_NAMES，或装一款中文字体"
    }
}

# ---------------------------------------------------------------- 9. 分层边界
$sectionTitle = "[9] 分层边界（core 无界面代码 / UI 不裸读 Battle 字段）"
$boundaryBad = @()
$srcCore = Join-Path $ProjectRoot "src\core"
if (Test-Path $srcCore) {
    # core 里不许出现 Control / Node / Tween / Theme 这些界面类型
    foreach ($f in (Get-ChildItem $srcCore -Filter "*.gd" -Recurse -File)) {
        $n = 0
        foreach ($line in (Get-Content $f.FullName)) {
            $n++
            if ($line.TrimStart().StartsWith("#")) { continue }
            if ($line -match "\b(Control|Node2D|CanvasItem|Tween|Theme|SceneTree)\b") {
                $boundaryBad += ("src/core/{0}:{1} 出现界面类型（core 不许依赖界面）" -f $f.Name, $n)
            }
        }
    }
}
$srcUi = Join-Path $ProjectRoot "src\ui"
if (Test-Path $srcUi) {
    # UI 不许直接摸 Battle 的内部字段（只许调方法）。白名单：公开方法调用不算。
    $uiPrivateFields = @("\.cards\b", "\.deck\b", "\.enemy_deck\b", "\.energy\b", "\.enemy_energy\b",
                         "\.turn\b", "\.first_move\b", "\.opening_phase\b", "\.log\b", "\.board\b")
    foreach ($f in (Get-ChildItem $srcUi -Filter "*.gd" -Recurse -File)) {
        $n = 0
        foreach ($line in (Get-Content $f.FullName)) {
            $n++
            $t = $line.TrimStart()
            if ($t.StartsWith("#")) { continue }
            foreach ($pat in $uiPrivateFields) {
                if ($line -match ("\b(battle|b)" + $pat)) {
                    $boundaryBad += ("src/ui/{0}:{1} 裸读 Battle 内部字段（应改为调 core 的只读快照）" -f $f.Name, $n)
                    break
                }
            }
        }
    }
}
if ($boundaryBad.Count -eq 0) {
    Say-Ok "分层边界干净（core 无界面类型、UI 无 Battle 裸读）"
} else {
    foreach ($e in $boundaryBad) { Say-Fail $e }
    Say-Info "约定见 docs/architecture.md：依赖方向固定 UI → core → data，core 不许反向依赖"
}

# ---------------------------------------------------------------- 10. 工具自检
$sectionTitle = "[10] 工具自检 tools/test_card_lib.gd"
$libTest = Join-Path $ProjectRoot "tools\test_card_lib.gd"
if (-not (Test-Path $libTest)) {
    Say-Info "还没有 tools/test_card_lib.gd（M4 之前属正常），跳过"
} else {
    $lout = & $Godot --headless --path $ProjectRoot --script res://tools/test_card_lib.gd 2>&1 | Out-String
    if ($lout.Contains("PASS") -and (-not $lout.Contains("[FAIL]")) -and (-not $lout.Contains("SCRIPT ERROR"))) {
        $m = [regex]::Match($lout, "共 (\d+) 项检查")
        $cnt = if ($m.Success) { $m.Groups[1].Value } else { "?" }
        Say-Ok ("CardLib 读写/校验/行级手术 {0} 项全通过" -f $cnt)
    } else {
        Say-Fail "tools/test_card_lib.gd 没过 —— 图形工具的写回逻辑不可信"
        Show-Section
        Write-Host $lout
        Say-Info "手动跑：& `$g --headless --path . --script res://tools/test_card_lib.gd"
    }
}

# ---------------------------------------------------------------- 11. 图形工具端到端
$sectionTitle = "[11] 图形工具端到端（单位卡制作工具的界面自检）"
$makerScene = Join-Path $ProjectRoot "tools\unit_maker.tscn"
$cardsFile = Join-Path $ProjectRoot "data\tables\cards.json"
if (-not (Test-Path $makerScene)) {
    Say-Info "还没有 tools/unit_maker.tscn（M4 之前属正常），跳过"
} else {
    # 自检会读写真数据文件。判据是「跑完和跑之前字节一致」，
    # 不能拿 git status 判 —— 学员可能正准备提交自己用工具改出来的卡，那不是残留。
    $hashBefore = $null
    if (Test-Path $cardsFile) { $hashBefore = (Get-FileHash $cardsFile -Algorithm SHA256).Hash }

    $mout = & $Godot --path $ProjectRoot --headless tools/unit_maker.tscn -- --selftest 2>&1 | Out-String
    if ($mout.Contains("PASS") -and (-not $mout.Contains("[FAIL]")) -and (-not $mout.Contains("SCRIPT ERROR"))) {
        $m = [regex]::Match($mout, "共 (\d+) 项检查")
        $cnt = if ($m.Success) { $m.Groups[1].Value } else { "?" }
        Say-Ok ("界面自检（选卡/改字段/保存/新建/删除/还原）{0} 项全通过" -f $cnt)
    } else {
        Say-Fail "单位卡制作工具界面自检没过 —— 工具可能写坏 cards.json"
        Show-Section
        Write-Host $mout
        Say-Info "手动跑：& `$g --path . --headless tools/unit_maker.tscn -- --selftest"
    }

    $hashAfter = $null
    if (Test-Path $cardsFile) { $hashAfter = (Get-FileHash $cardsFile -Algorithm SHA256).Hash }
    if ($hashBefore -eq $hashAfter) {
        Say-Ok "自检跑完 cards.json 与跑之前逐字节一致（数据已还原）"
    } elseif ($hashBefore -eq $null -or $hashAfter -eq $null) {
        Say-Warn "cards.json 在自检前后有一侧不存在，无法比对"
    } else {
        Say-Fail "自检跑完 cards.json 与跑之前不一致 —— 工具没把数据还原干净"
        Say-Info "手工核对：git diff data/tables/cards.json；确认是自检残留后 git checkout -- 它"
    }
}

# ---------------------------------------------------------------- 结论
Write-Host ("------------------------------")
if ($fails -eq 0) {
    Write-Host ("[详细自检] PASS（{0} 项通过、{1} 条提醒）" -f $oks, $warns) -ForegroundColor Green
    exit 0
}
Write-Host ("[详细自检] FAIL（{0} 条失败、{1} 条提醒）" -f $fails, $warns) -ForegroundColor Red
exit 1
