@echo off
set HDC="C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"

echo ========================================
echo Viewing FreeRDP Session Logs
echo ========================================
echo.

"%HDC%" shell hilog -T SessionPage -T FreeRDP
