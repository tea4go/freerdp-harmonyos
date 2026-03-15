@echo off
REM 快速运行 FreeRDP HarmonyOS 应用
REM 自动卸载、安装、启动应用

setlocal
set HDC="C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
set HAP_FILE=entry\build\default\outputs\default\entry-default-signed.hap

echo.
echo ============================================
echo    快速部署 FreeRDP HarmonyOS
echo ============================================
echo.

REM 检查 HAP 文件
if not exist "%HAP_FILE%" (
    echo [错误] HAP 文件不存在: %HAP_FILE%
    echo 请先编译项目: build_windows.cmd
    pause
    exit /b 1
)

REM 检查设备
echo [1/4] 检查设备连接...
%HDC% list targets >nul 2>&1
if errorlevel 1 (
    echo [错误] 没有检测到设备
    echo 请确保设备已连接并开启 USB 调试
    pause
    exit /b 1
)
echo [OK] 设备已连接
echo.

REM 停止应用
echo [2/4] 停止旧版本应用...
%HDC% shell aa force-stop com.yjsoft.freerdp 2>nul
echo [OK] 应用已停止
echo.

REM 安装应用
echo [3/4] 安装新版本应用...
%HDC% install -r "%HAP_FILE%"
if errorlevel 1 (
    echo [错误] 安装失败
    pause
    exit /b 1
)
echo [OK] 安装成功
echo.

REM 启动应用
echo [4/4] 启动应用...
%HDC% shell aa start -a EntryAbility -b com.yjsoft.freerdp
if errorlevel 1 (
    echo [错误] 启动失败
    pause
    exit /b 1
)
echo [OK] 应用已启动
echo.

echo ============================================
echo           部署完成！
echo ============================================
echo.
echo 💡 查看日志: hdc hilog -x ^| find "freerdp"
echo 💡 停止应用: hdc shell aa force-stop com.yjsoft.freerdp
echo.

REM 可选：自动启动日志监控
set /p showlog="是否查看实时日志? (y/n): "
if /i "%showlog%"=="y" (
    echo.
    echo 显示实时日志（按 Ctrl+C 退出）...
    echo.
    %HDC% hilog -x | find "freerdp"
)

pause
