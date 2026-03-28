$env:DEVECO_SDK_HOME = "C:\Program Files\Huawei\DevEco Studio\sdk"
$env:NODE_HOME = "C:\Program Files\Huawei\DevEco Studio\tools\node"
$env:HOS_SDK_HOME = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony"
Set-Location "D:\MyWork\GitCode\freerdp-harmonyos"
Write-Host "Building FreeRDP HarmonyOS..."
Write-Host "DEVECO_SDK_HOME: $env:DEVECO_SDK_HOME"
Write-Host "NODE_HOME: $env:NODE_HOME"
& "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --no-daemon
