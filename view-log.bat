@echo off
REM FreeRDP HarmonyOS 日志查看工具
REM 提供多种日志查看选项

setlocal
set HDC="C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
set LOG_FILE=freerdp_debug_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%.log
set LOG_FILE=%LOG_FILE: =0%

:menu
cls
echo.
echo ============================================
echo    FreeRDP HarmonyOS 日志查看工具
echo ============================================
echo.
echo 请选择日志查看模式:
echo.
echo   [1] 实时日志 - FreeRDP 相关
echo   [2] 实时日志 - 仅错误和警告
echo   [3] 实时日志 - 完整（所有日志）
echo   [4] 最近 50 行 - FreeRDP 相关
echo   [5] 最近 100 行 - 完整日志
echo   [6] 保存日志到文件
echo   [7] 清空日志缓冲区
echo   [8] 查看连接相关日志
echo   [9] 查看 Native 库日志
echo   [0] 退出
echo.
set /p choice="请输入选项 (0-9): "

if "%choice%"=="1" goto realtime_freerdp
if "%choice%"=="2" goto realtime_errors
if "%choice%"=="3" goto realtime_all
if "%choice%"=="4" goto recent_50
if "%choice%"=="5" goto recent_100
if "%choice%"=="6" goto save_log
if "%choice%"=="7" goto clear_log
if "%choice%"=="8" goto connection_log
if "%choice%"=="9" goto native_log
if "%choice%"=="0" exit /b 0

echo [错误] 无效选项
pause
goto menu

:realtime_freerdp
echo.
echo [实时日志 - FreeRDP] 按 Ctrl+C 退出
echo ============================================
%HDC% hilog -x 2>&1 | findstr /i "freerdp FreeRDP RDP Session"
goto menu

:realtime_errors
echo.
echo [实时日志 - 错误和警告] 按 Ctrl+C 退出
echo ============================================
%HDC% hilog -x 2>&1 | findstr /i "ERROR WARN FATAL"
goto menu

:realtime_all
echo.
echo [实时日志 - 完整] 按 Ctrl+C 退出
echo ============================================
%HDC% hilog -x
goto menu

:recent_50
echo.
echo [最近 50 行 - FreeRDP]
echo ============================================
%HDC% shell hilog -x 2>&1 | findstr /i "freerdp FreeRDP" | more +50
echo.
pause
goto menu

:recent_100
echo.
echo [最近 100 行 - 完整]
echo ============================================
%HDC% shell hilog -x 2>&1 | more +100
echo.
pause
goto menu

:save_log
echo.
echo [保存日志到文件]
echo ============================================
echo 正在收集日志...
%HDC% hilog -x > "%LOG_FILE%" 2>&1
echo [OK] 日志已保存到: %LOG_FILE%
echo.
echo 提示: 可以用文本编辑器打开查看
notepad "%LOG_FILE%"
goto menu

:clear_log
echo.
echo [清空日志缓冲区]
echo ============================================
%HDC% shell hilog -r
echo [OK] 日志已清空
echo.
pause
goto menu

:connection_log
echo.
echo [连接相关日志] 按 Ctrl+C 退出
echo ============================================
echo 显示包含以下关键词的日志:
echo   - Connecting
echo   - Connection
echo   - Connected
echo   - Disconnected
echo   - OnConnection
echo   - 192.168
echo.
%HDC% hilog -x 2>&1 | findstr /i "Connecting Connection Connected Disconnected OnConnection 192.168"
goto menu

:native_log
echo.
echo [Native 库日志] 按 Ctrl+C 退出
echo ============================================
echo 显示包含以下关键词的日志:
echo   - NAPI
echo   - FreeRDP
echo   - native
echo   - SSL
echo   - OpenSSL
echo.
%HDC% hilog -x 2>&1 | findstr /i "NAPI FreeRDP native SSL OpenSSL libfreerdp"
goto menu
