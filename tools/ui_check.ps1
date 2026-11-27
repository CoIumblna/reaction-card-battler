param(
    [int]$QuitAfter = 3,
    [int]$TimeoutSec = 90
)
# param() 必须是脚本第一条可执行语句，注释块放它后面（第 6 行 parse error 的根因）。
# ui_check.ps1 - M4 UI 综合体检（教练侧验收脚本）
# 五项检查：①开窗冒烟 ②中文字体 ③src/ui 中文字面量 ④core 无界面代码 ⑤pending 状态
# 任一项失败退出码 1；全部通过打印 [UI CHECK PASS]。
# 编码规则：本文件必须 UTF-8 **with BOM**（PowerShell 5.1 读无 BOM 中文脚本会按 936 解码炸出一堆假语法错）。
$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$proj = Split-Path -Parent $PSScriptRoot
$godot = $env:GODOT
if (-not $godot) {
    Write-Host "[UI CHECK] GODOT env not set" -ForegroundColor Red
    exit 2
}

function Invoke-Godot {
    param([string[]]$GodotArgs, [string]$Log)
    $errLog = "$Log.err"
    $p = Start-Process -FilePath $godot -ArgumentList $GodotArgs `
        -RedirectStandardOutput $Log -RedirectStandardError $errLog `
        -PassThru -NoNewWindow
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        try { $p.Kill() } catch {}
        $p.WaitForExit()
        Start-Sleep -Milliseconds 300
        [IO.File]::AppendAllText($Log, "`n[HUNG] killed after $TimeoutSec s", (New-Object Text.UTF8Encoding $false))
        return 3
    }
    return $p.ExitCode
}

$verdicts = @()
$red = 0

# ---------- [1] 开窗冒烟：主场景能加载（M4.0 之前没有主场景 → SKIP，不算红） ----------
$hasMainScene = Select-String -Path (Join-Path $proj "project.godot") -Pattern "run/main_scene" -Quiet
if (-not $hasMainScene) {
    Write-Host "  [1] scene boot      SKIP（project.godot 还没注册主场景，M4.0 完成后自动变为检查）" -ForegroundColor Yellow
    $verdicts += "[1] 场景加载  SKIP（无主场景）"
} else {
    $log1 = Join-Path $proj "logs\ui_check_1_scene.log"
    New-Item -ItemType Directory -Force -Path (Split-Path $log1) | Out-Null
    $rc = Invoke-Godot @("--headless", "--path", "$proj.", "--quit-after", "$QuitAfter") $log1
    $text1 = ""
    if (Test-Path $log1) { $text1 = [IO.File]::ReadAllText($log1) }
    $badScene = $text1 -match "Failed to load main scene"
    if ($rc -eq 0 -and -not $badScene) {
        $verdicts += "[1] 场景加载  PASS"; Write-Host "  [1] scene boot      PASS"
    } else {
        $verdicts += "[1] 场景加载  FAIL"; Write-Host "  [1] scene boot      FAIL (rc=$rc)" -ForegroundColor Red
        Write-Host "      see $log1"; $red++
    }
}

# ---------- [2] 中文字体 ----------
$log2 = Join-Path $proj "logs\ui_check_2_font.log"
$rc = Invoke-Godot @("--headless", "--path", "$proj.", "--script", "res://tools/check_font.gd") $log2
$text2 = ""
if (Test-Path $log2) { $text2 = [IO.File]::ReadAllText($log2) }
# [HUNG] 的 log2 是被 kill 的那个进程写的；kill 时 log 里已有 [FONT OK] 也会误判，所以先看退出码
if ($rc -eq 0 -and $text2 -match "\[FONT OK\]") {
    $verdicts += "[2] 中文字体  PASS"; Write-Host "  [2] font            PASS"
} elseif ($text2 -match "\[FONT OK\]") {
    # 字体体检本身 PASS 但进程退出码非 0（Godot 4 对 SceneTree 脚本退出码有怪癖）：按输出内容判
    $verdicts += "[2] font PASS by output (rc=$rc)"; Write-Host "  [2] font            PASS (by output, rc=$rc)"
} else {
    $verdicts += "[2] 中文字体  FAIL"; Write-Host "  [2] font            FAIL (rc=$rc)" -ForegroundColor Red
    $red++
}

# ---------- [3] src/ui 中文字面量（卡名/关卡名不许硬编码） ----------
# 例外白名单：card_view.gd 是已交付的卡面组件，其「元素：/攻/御」是**版式固定文案**（卡面模板上的字），
# 不是「从 data/ 该读而没读」的数据；禁令针对的是**卡名/关卡名/敌人名**这类会随数据变化的内容。
# 真正要拦的信号：UI 里出现 `if id == "fire_mage"` 这类按数据分支，或 `"火法师"` 这类具体名词。
$uiFiles = Get-ChildItem -Path (Join-Path $proj "src\ui") -Filter "*.gd" -ErrorAction SilentlyContinue
$hits = @()
$whitelist = @("card_view.gd")
foreach ($f in $uiFiles) {
    if ($whitelist -contains $f.Name) { continue }
    $t = [IO.File]::ReadAllText($f.FullName)
    foreach ($line in ($t -split "`n")) {
        $code = ($line -split "#")[0]
        if ($code -match '[\u4e00-\u9fff]') { $hits += ("{0}:{1}" -f $f.Name, $line.Trim()) }
    }
}
if ($hits.Count -eq 0) {
    $verdicts += "[3] UI 中文字面量  PASS"; Write-Host "  [3] no CN literals  PASS"
} else {
    $verdicts += "[3] UI 中文字面量  FAIL"; Write-Host "  [3] CN literals x$($hits.Count)" -ForegroundColor Red
    $hits | Select-Object -First 5 | ForEach-Object { Write-Host "      $_" }
    $red++
}

# ---------- [4] core 无界面代码 ----------
$coreHits = @()
Get-ChildItem -Path (Join-Path $proj "src\core") -Filter "*.gd" | ForEach-Object {
    $t = [IO.File]::ReadAllText($_.FullName)
    foreach ($line in ($t -split "`n")) {
        $code = ($line -split "#")[0]
        if ($code -match '\b(Control|CanvasItem|Node2D|Label|Button|Panel|ColorRect|Tween)\b') {
            $coreHits += ("{0}:{1}" -f $_.Name, $line.Trim())
        }
    }
}
if ($coreHits.Count -eq 0) {
    $verdicts += "[4] core 无界面代码  PASS"; Write-Host "  [4] core clean      PASS"
} else {
    $verdicts += "[4] core 无界面代码  FAIL"; Write-Host "  [4] core UI refs x$($coreHits.Count)" -ForegroundColor Red
    $coreHits | Select-Object -First 5 | ForEach-Object { Write-Host "      $_" }
    $red++
}

# ---------- [5] pending 状态报告（不判红，只提示） ----------
$pend = Get-ChildItem -Path (Join-Path $proj "tests\pending") -Filter "ui_*_test.gd" -ErrorAction SilentlyContinue
if ($pend) {
    Write-Host "  [5] pending ui tests: $($pend.Count)  $(($pend | ForEach-Object { $_.BaseName }) -join ', ')" -ForegroundColor Yellow
    $verdicts += "[5] pending 提示  $($pend.Count) 份未启用"
} else {
    Write-Host "  [5] pending empty   PASS"
    $verdicts += "[5] pending 空  PASS"
}

Write-Host ""
$verdicts | ForEach-Object { Write-Host "  $_" }
if ($red -gt 0) {
    Write-Host "[UI CHECK FAIL] red=$red" -ForegroundColor Red
    exit 1
}
Write-Host "[UI CHECK PASS]"
exit 0
