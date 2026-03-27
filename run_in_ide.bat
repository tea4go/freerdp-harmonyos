@echo off
echo ========================================
echo   启动 DevEco Studio 并运行项目
echo ========================================
echo.
echo 即将启动 DevEco Studio...
echo 项目路径: D:\MyWork\GitCode\freerdp-harmonyos
echo.
echo 请在 DevEco Studio 中:
echo   1. 项目打开后，点击 Run 按钮 (绿色三角形)
echo   2. 或按快捷键: Shift + F10
echo   3. 选择设备: 192.168.52.79:45913
echo.

start "" "C:\Program Files\Huawei\DevEco Studio\bin\devecostudio64.exe" "D:\MyWork\GitCode\freerdp-harmonyos"

echo.
echo DevEco Studio 启动中...
echo 请在 IDE 中点击 Run 按钮运行应用
echo.
pause
