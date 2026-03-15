$HDC = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   监控自动连接日志" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 等待几秒让应用启动
Write-Host "等待应用启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 查看最近的日志
Write-Host "查看最近 80 行日志:" -ForegroundColor Green
& $HDC shell hilog -T SessionPage -T FreeRDP -T RDP 2>&1 | Select-Object -Last 80
