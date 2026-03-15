@echo off
set HDC="C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"

echo =============================================
echo    查看自动连接日志
echo =============================================
echo.

echo 等待 5 秒让应用启动...
timeout /t 5 >nul 2>&1

echo.
echo 查看最近 100 行日志:
echo ---------------------------------------------
"%HDC%" shell hilog -T SessionPage -T FreeRDP 2>&1 | more +100
