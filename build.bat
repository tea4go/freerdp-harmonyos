@echo off
setlocal

set NODE_HOME=C:\Program Files\Huawei\DevEco Studio\tools\node
set DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony
set HOS_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony
set PATH=%NODE_HOME%;%PATH%

echo Building FreeRDP HarmonyOS...
echo NODE_HOME=%NODE_HOME%
echo DEVECO_SDK_HOME=%DEVECO_SDK_HOME%

"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --no-daemon

endlocal
