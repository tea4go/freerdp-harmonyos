@echo off
REM FreeRDP HarmonyOS 诊断���具
REM 快速检查应用状态和问题

setlocal enabledelayedexpansion
set HDC="C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"

echo.
echo ============================================
echo    FreeRDP HarmonyOS 诊断工具 v1.0
echo ============================================
echo.

REM 检查 hdc 工具
%HDC% version >nul 2>&1
if errorlevel 1 (
    echo [错误] hdc 工具不可用
    echo 请检查路径: %HDC%
    echo 或更新 HDC 环境变量
    pause
    exit /b 1
)

echo [1/8] 检查设备连接...
echo ----------------------------------------
%HDC% list targets 2>&1
if errorlevel 1 (
    echo [警告] 没有检测到设备
    echo 请确保:
    echo   1. 设备已通过 USB 连接
    echo   2. 设备已开启开发者模式和 USB 调试
    echo   3. 已授权此电脑进行调试
    echo.
    set /p continue="是否继续检查? (y/n): "
    if /i not "!continue!"=="y" exit /b 1
)
echo.

echo [2/8] 检查设备架构...
echo ----------------------------------------
%HDC% shell getprop ro.product.cpu.abi 2>&1
echo [提示] 应该显示: arm64-v8a
echo.

echo [3/8] 检查应用安装状态...
echo ----------------------------------------
%HDC% shell pm list packages -f com.yjsoft.freerdp 2>&1 | find "freerdp"
if errorlevel 1 (
    echo [警告] 应用未安装
) else (
    echo [OK] 应用已安装
)
echo.

echo [4/8] 检查应用进程...
echo ----------------------------------------
%HDC% shell "ps -ef | grep freerdp" 2>&1 | find /v "grep"
if errorlevel 1 (
    echo [提示] 应用未运行
) else (
    echo [OK] 应用正在运行
)
echo.

echo [5/8] 检查最近的应用日志（最后20行）...
echo ----------------------------------------
%HDC% shell hilog -x 2>&1 | find "freerdp" | more +20
if errorlevel 1 (
    echo [提示] 没有找到相关日志
)
echo.

echo [6/8] 检查网络连接...
echo ----------------------------------------
echo 正在检查到远程桌面的连接...
%HDC% shell "netstat -anp 2>/dev/null | grep 3389" 2>&1
if errorlevel 1 (
    echo [提示] 没有活动的 RDP 连接
)
echo.

echo [7/8] 检查应用权限...
echo ----------------------------------------
%HDC% shell bm dump -n com.yjsoft.freerdp 2>&1 | find "permission"
echo.

echo [8/8] 检查 Native 库...
echo ----------------------------------------
echo 检查本地编译的 HAP 文件...
if exist "entry\build\default\outputs\default\entry-default-signed.hap" (
    echo [OK] HAP 文件存在
    dir "entry\build\default\outputs\default\entry-default-signed.hap" | find "entry-default"
) else (
    echo [警告] HAP 文件不存在，需要编译
)
echo.

echo ============================================
echo              诊断完成
echo ============================================
echo.
echo 💡 常用命令:
echo   查看完整日志:    hdc hilog
echo   重启应用:        hdc shell aa force-stop com.yjsoft.freerdp ^&^& hdc shell aa start -a EntryAbility -b com.yjsoft.freerdp
echo   重新安装:        hdc install -r entry\build\default\outputs\default\entry-default-signed.hap
echo.
pause
