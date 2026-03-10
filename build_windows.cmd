@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  build_windows.cmd  --  freerdp-harmonyos HAP 构建脚本
::
::  用法:
::    build_windows.cmd [debug|release] ["DevEco Studio 路径"]
::
::  示例:
::    build_windows.cmd
::    build_windows.cmd release
::    build_windows.cmd debug "D:\Program Files\Huawei\DevEco Studio"
:: ============================================================

echo =====================================================
echo  freerdp-harmonyos  Windows 命令行构建
echo =====================================================
echo.

:: ----------------------------------------------------------
:: 1. 解析参数
:: ----------------------------------------------------------
set BUILD_MODE=debug
if /i "%~1"=="release" set BUILD_MODE=release
if /i "%~1"=="debug"   set BUILD_MODE=debug

set DEVECO_CUSTOM=%~2

:: ----------------------------------------------------------
:: 2. 定位 DevEco Studio 安装目录
:: ----------------------------------------------------------
if not "%DEVECO_CUSTOM%"=="" (
    set DEVECO_HOME=%DEVECO_CUSTOM%
    goto :CHECK_DEVECO
)

:: 优先检查系统级 DEVECO_HOME 环境变量
if not "%DEVECO_HOME%"=="" goto :CHECK_DEVECO

:: 尝试常见安装路径
for %%P in (
    "C:\Program Files\Huawei\DevEco Studio"
    "D:\Program Files\Huawei\DevEco Studio"
    "E:\Program Files\Huawei\DevEco Studio"
    "C:\Huawei\DevEco Studio"
    "D:\Huawei\DevEco Studio"
) do (
    if exist "%%~P\tools\hvigor\bin\hvigorw.bat" (
        set DEVECO_HOME=%%~P
        goto :CHECK_DEVECO
    )
)

echo [FAIL] 未找到 DevEco Studio 安装目录！
echo.
echo  请通过以下方式之一指定路径：
echo    1. 传入参数: build_windows.cmd debug "C:\Your\DevEco Studio"
echo    2. 设置环境变量: set DEVECO_HOME=C:\Your\DevEco Studio
echo    3. 将 DevEco Studio 安装到默认路径: C:\Program Files\Huawei\DevEco Studio
echo.
exit /b 1

:CHECK_DEVECO
echo [INFO] DevEco Studio 路径: %DEVECO_HOME%

:: ----------------------------------------------------------
:: 3. 验证关键工具存在
:: ----------------------------------------------------------
set HVIGORW=%DEVECO_HOME%\tools\hvigor\bin\hvigorw.bat
set OHPM=%DEVECO_HOME%\tools\ohpm\bin\ohpm.bat
set SDK_HOME=%DEVECO_HOME%\sdk

if not exist "%HVIGORW%" (
    echo [FAIL] 找不到 hvigorw: %HVIGORW%
    exit /b 1
)
echo [OK]   hvigorw 已找到

if not exist "%SDK_HOME%\default\openharmony" (
    echo [FAIL] 找不到 HarmonyOS SDK: %SDK_HOME%\default\openharmony
    echo        请确认 DevEco Studio 已完成 SDK 下载（Tools → SDK Manager）
    exit /b 1
)
echo [OK]   SDK 已找到: %SDK_HOME%

:: ----------------------------------------------------------
:: 4. 设置 DEVECO_SDK_HOME（hvigorw 必需）
:: ----------------------------------------------------------
set DEVECO_SDK_HOME=%SDK_HOME%
echo [OK]   DEVECO_SDK_HOME=%DEVECO_SDK_HOME%

:: ----------------------------------------------------------
:: 5. 检查签名文件（build-profile.json5 中配置的路径）
:: ----------------------------------------------------------
echo.
echo [INFO] 检查签名文件...
set SIGNING_OK=1
set OHOS_CONFIG=%USERPROFILE%\.ohos\config

if not exist "%OHOS_CONFIG%" (
    echo [WARN] 签名目录不存在: %OHOS_CONFIG%
    echo        请在 DevEco Studio 中打开项目并自动生成签名
    set SIGNING_OK=0
) else (
    set FOUND_CER=0
    set FOUND_P12=0
    set FOUND_P7B=0
    for %%F in ("%OHOS_CONFIG%\default_freerdp-harmonyos_*.cer") do set FOUND_CER=1
    for %%F in ("%OHOS_CONFIG%\default_freerdp-harmonyos_*.p12") do set FOUND_P12=1
    for %%F in ("%OHOS_CONFIG%\default_freerdp-harmonyos_*.p7b") do set FOUND_P7B=1

    if "!FOUND_CER!"=="1" (echo [OK]   .cer 签名证书) else (echo [WARN] 缺少 .cer 文件 & set SIGNING_OK=0)
    if "!FOUND_P12!"=="1" (echo [OK]   .p12 密钥库)   else (echo [WARN] 缺少 .p12 文件 & set SIGNING_OK=0)
    if "!FOUND_P7B!"=="1" (echo [OK]   .p7b 调试证书) else (echo [WARN] 缺少 .p7b 文件 & set SIGNING_OK=0)
)

if "!SIGNING_OK!"=="0" (
    echo.
    echo [FAIL] 签名文件不完整，Debug HAP 无法签名！
    echo        解决方案: 在 DevEco Studio 中打开项目
    echo        File -^> Project Structure -^> Signing Configs -^> Automatically generate signature
    echo.
    exit /b 1
)

:: ----------------------------------------------------------
:: 6. 执行构建
:: ----------------------------------------------------------
echo.
echo =====================================================
echo  开始构建: %BUILD_MODE% 模式
echo =====================================================
echo.

call "%HVIGORW%" assembleHap ^
    --mode module ^
    -p module=entry@default ^
    -p product=default ^
    -p buildMode=%BUILD_MODE%

set BUILD_EXIT=%ERRORLEVEL%

:: ----------------------------------------------------------
:: 7. 输出结果
:: ----------------------------------------------------------
echo.
if %BUILD_EXIT% EQU 0 (
    echo =====================================================
    echo  构建成功！
    echo =====================================================
    echo.
    set HAP_DIR=%~dp0entry\build\default\outputs\default
    echo  输出目录: !HAP_DIR!
    echo.
    if exist "!HAP_DIR!\entry-default-signed.hap" (
        for %%F in ("!HAP_DIR!\entry-default-signed.hap") do (
            set /a SIZE_MB=%%~zF/1048576
            echo  [HAP] entry-default-signed.hap   ^(!SIZE_MB! MB^)  ← 可直接安装
        )
    )
    if exist "!HAP_DIR!\entry-default-unsigned.hap" (
        for %%F in ("!HAP_DIR!\entry-default-unsigned.hap") do (
            set /a SIZE_MB=%%~zF/1048576
            echo  [HAP] entry-default-unsigned.hap ^(!SIZE_MB! MB^)
        )
    )
    echo.
) else (
    echo =====================================================
    echo  构建失败！请查看上方错误日志
    echo =====================================================
    echo.
    echo  常见原因:
    echo    1. DEVECO_SDK_HOME 路径不正确
    echo    2. 签名文件已过期或路径变更
    echo    3. oh_modules 依赖未安装（运行 ohpm install）
    echo    4. ArkTS 编译错误（查看详细日志）
    echo.
    exit /b 1
)

endlocal
