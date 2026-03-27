@echo off
REM 自动构建和运行脚本
setlocal enabledelayedexpansion

echo ========================================
echo   FreeRDP HarmonyOS 自动构建和运行
echo ========================================
echo.

REM 设置环境变量
set DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk
set HVIGORW=C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat
set HDC=C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe

echo [步骤 1/5] 检查设备连接...
"%HDC%" list targets >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到设备，请连接设备后重试
    pause
    exit /b 1
)
echo [OK] 设备已连接

echo.
echo [步骤 2/5] 停止旧版本应用...
"%HDC%" shell aa force-stop com.yjsoft.freerdp 2>nul
echo [OK] 应用已停止

echo.
echo [步骤 3/5] 清理构建缓存...
"%HVIGORW%" clean >nul 2>&1
echo [OK] 缓存已清理

echo.
echo [步骤 4/5] 构建应用...
echo 这可能需要几分钟，请耐心等待...
"%HVIGORW%" assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug

if errorlevel 1 (
    echo.
    echo [错误] 构建失败！
    echo.
    echo 可能的原因：
    echo   1. 签名文件缺失或损坏
    echo   2. 代码编译错误
    echo.
    echo 推荐解决方案：
    echo   在 DevEco Studio 中打开项目
    echo   File ^> Project Structure ^> Signing Configs ^> Automatically generate signature
    echo   然后点击 Run 按钮运行
    echo.
    pause
    exit /b 1
)

echo [OK] 构建成功

echo.
echo [步骤 5/5] 安装并启动应用...

REM 查找生成的 HAP 文件
set HAP_SIGNED=entry\build\default\outputs\default\entry-default-signed.hap
set HAP_UNSIGNED=entry\build\default\outputs\default\entry-default-unsigned.hap

if exist "%HAP_SIGNED%" (
    echo 找到已签名的 HAP 文件
    "%HDC%" install -r "%HAP_SIGNED%"
) else if exist "%HAP_UNSIGNED%" (
    echo 找到未签名的 HAP 文件，尝试安装...
    "%HDC%" install -r "%HAP_UNSIGNED%"
    if errorlevel 1 (
        echo.
        echo [错误] 未签名的 HAP 无法安装
        echo.
        echo 请在 DevEco Studio 中生成签名：
        echo   File ^> Project Structure ^> Signing Configs ^> Automatically generate signature
        echo   然后重新运行此脚本
        echo.
        pause
        exit /b 1
    )
) else (
    echo [错误] 找不到 HAP 文件
    pause
    exit /b 1
)

if errorlevel 1 (
    echo [错误] 安装失败
    pause
    exit /b 1
)

echo [OK] 安装成功

REM 启动应用
"%HDC%" shell aa start -a EntryAbility -b com.yjsoft.freerdp
if errorlevel 1 (
    echo [错误] 启动失败
    pause
    exit /b 1
)

echo [OK] 应用已启动

echo.
echo ========================================
echo   部署完成！
echo ========================================
echo.
echo 应用已在设备上启动
echo 请检查设备屏幕，应该能看到远程桌面画面
echo.
echo 查看实时日志：
echo   %HDC% hilog -x ^| findstr "SessionPage freerdp"
echo.

REM 询问是否查看日志
set /p showlog="是否查看实时日志? (y/n): "
if /i "%showlog%"=="y" (
    echo.
    echo 显示实时日志（按 Ctrl+C 退出）...
    echo.
    "%HDC%" hilog -x | findstr "SessionPage LibFreeRDP OnGraphics PixelMap freerdp"
)

pause
