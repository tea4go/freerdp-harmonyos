# FreeRDP HarmonyOS - PowerShell 工具集

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "help",

    [Parameter(Mandatory=$false)]
    [string]$Filter = "freerdp",

    [Parameter(Mandatory=$false)]
    [int]$Lines = 50
)

$HDC_PATH = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
$HAP_FILE = "entry\build\default\outputs\default\entry-default-signed.hap"
$PACKAGE = "com.yjsoft.freerdp"
$ABILITY = "EntryAbility"

function Test-HDC {
    try {
        & $HDC_PATH version | Out-Null
        return $true
    } catch {
        Write-Error "HDC 工具不可用: $HDC_PATH"
        return $false
    }
}

function Get-Devices {
    if (-not (Test-HDC)) { return }

    Write-Host "`n📱 已连接的设备:" -ForegroundColor Cyan
    & $HDC_PATH list targets
}

function Install-App {
    if (-not (Test-HDC)) { return }

    Write-Host "`n📦 安装应用..." -ForegroundColor Yellow

    if (-not (Test-Path $HAP_FILE)) {
        Write-Error "HAP 文件不存在: $HAP_FILE"
        Write-Host "请先编译项目: hvigorw assembleHap --mode module -p product=default -p buildMode=debug" -ForegroundColor Yellow
        return
    }

    & $HDC_PATH install -r $HAP_FILE

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 安装成功" -ForegroundColor Green
    } else {
        Write-Error "安装失败"
    }
}

function Start-App {
    if (-not (Test-HDC)) { return }

    Write-Host "`n🚀 启动应用..." -ForegroundColor Yellow
    & $HDC_PATH shell aa start -a $ABILITY -b $PACKAGE

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 启动成功" -ForegroundColor Green
    } else {
        Write-Error "启动失败"
    }
}

function Stop-App {
    if (-not (Test-HDC)) { return }

    Write-Host "`n🛑 停止应用..." -ForegroundColor Yellow
    & $HDC_PATH shell aa force-stop $PACKAGE

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 应用已停止" -ForegroundColor Green
    }
}

function Restart-App {
    Stop-App
    Start-App
}

function Show-Logs {
    if (-not (Test-HDC)) { return }

    Write-Host "`n📋 实时日志 (过滤: $Filter)..." -ForegroundColor Cyan
    Write-Host "按 Ctrl+C 退出`n" -ForegroundColor Yellow

    & $HDC_PATH hilog -x 2>&1 | Select-String -Pattern $Filter
}

function Show-RecentLogs {
    if (-not (Test-HDC)) { return }

    Write-Host "`n📋 最近 $Lines 行日志 (过滤: $Filter):" -ForegroundColor Cyan

    $logs = (& $HDC_PATH shell hilog -x 2>&1 | Select-String -Pattern $Filter)
    $logs | Select-Object -Last $Lines
}

function Clear-Logs {
    if (-not (Test-HDC)) { return }

    Write-Host "`n🗑️ 清空日志缓冲区..." -ForegroundColor Yellow
    & $HDC_PATH shell hilog -r

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 日志已清空" -ForegroundColor Green
    }
}

function Save-Logs {
    if (-not (Test-HDC)) { return }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logfile = "freerdp_log_$timestamp.txt"

    Write-Host "`n💾 保存日志到: $logfile" -ForegroundColor Yellow

    & $HDC_PATH hilog -x 2>&1 | Out-File -Encoding UTF8 $logfile

    Write-Host "✅ 日志已保存" -ForegroundColor Green
}

function Show-Status {
    if (-not (Test-HDC)) { return }

    Write-Host "`n📊 应用状态" -ForegroundColor Cyan
    Write-Host "================================`n" -ForegroundColor Gray

    # 检查应用安装
    Write-Host "应用安装状态:" -ForegroundColor Yellow
    & $HDC_PATH shell pm list packages 2>&1 | Select-String $PACKAGE

    # 检查进程
    Write-Host "`n进程状态:" -ForegroundColor Yellow
    & $HDC_PATH shell "ps -ef 2>/dev/null" 2>&1 | Select-String "freerdp"

    # 设备信息
    Write-Host "`n设备信息:" -ForegroundColor Yellow
    Write-Host "架构: " -NoNewline
    & $HDC_PATH shell getprop ro.product.cpu.abi
}

function Show-Help {
    Write-Host @"

FreeRDP HarmonyOS - 开发工具集

用法:
    .\dev-tools.ps1 -Action <命令> [-Filter <过滤词>] [-Lines <行数>]

命令:
    devices      - 列出连接的设备
    install      - 安装应用
    start        - 启动应用
    stop         - 停止应用
    restart      - 重启应用
    logs         - 查看实时日志
    recent       - 查看最近的日志
    clear        - 清空日志缓冲区
    save         - 保存日志到文件
    status       - 显示应用状态
    help         - 显示此帮助信息

示例:
    .\dev-tools.ps1 -Action install
    .\dev-tools.ps1 -Action logs -Filter "Connection"
    .\dev-tools.ps1 -Action recent -Lines 100
    .\dev-tools.ps1 -Action restart

"@
}

# 主逻辑
switch ($Action.ToLower()) {
    "devices"    { Get-Devices }
    "install"    { Install-App }
    "start"      { Start-App }
    "stop"       { Stop-App }
    "restart"    { Restart-App }
    "logs"       { Show-Logs }
    "recent"     { Show-RecentLogs }
    "clear"      { Clear-Logs }
    "save"       { Save-Logs }
    "status"     { Show-Status }
    "help"       { Show-Help }
    default      {
        Write-Error "未知命令: $Action"
        Show-Help
    }
}
