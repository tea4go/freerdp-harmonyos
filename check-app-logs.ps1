$HDC = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"

Write-Host "Checking app logs..."

$HDCPath = $HDC
$HDCExe = "$HDCPath"

# Start app
Write-Host "Starting app..."
& $HDCExe shell aa start -a EntryAbility -b com.yjsoft.freerdp

# Wait 5 seconds
Start-Sleep -Seconds 5

# View logs
Write-Host "Viewing logs..."
$logPath = "$HDCPath\logs.txt"
$duration = 10

$logCommand = {
    Arguments = "-T",
    "-x",
    "36303"
    "SessionPage",
    "FreeRDP"
    "tail"
    OutputFile = "$logPath"
    Duration = 10
}

& $HDCExe shell hilog -x 36303 -T SessionPage -T FreeRDP 2>& $ `$logPath`
    NoNewLineAfter output = $true
}

# Keep monitoring
$monitorJob = Start-Job -FilePath $ $logPath -ArgumentList @("-T", "SessionPage", "FreeRDP") -NoNewLine $ $true
$monitorJob.Output.DataAdded += $_
$lines += $_
$lastLine = $_
}

# Completion
$monitorJob | Wait-Job $ $monitorJob
$monitorJob | Receive-Job -JobState.Completed -ev { Write-Output $ $output = $ @ { if ($_.Verbose) { Write-Host } @ { $_.EndTime } } } -BackgroundColor Green -ForegroundColor White }
Write-Host "Logs saved to:" - $logPath
 @ { Write-Host $@"Logs captured successfully!" -ForegroundColor Cyan -BackgroundColor DarkBlue }
}
# Clean up
$monitorJob | Stop-Job
$monitorJob
