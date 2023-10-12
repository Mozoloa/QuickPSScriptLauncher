if (Test-Path '.git') {
    Write-Host 'Relaunching in update mode, do not close this window'
    git pull
    Start-Sleep -Seconds 2; # Sleep for 2 seconds to give the user time to see the result
    Write-Host 'Opening...'
    & main.ps1; # Relaunch the script
}
else {
    Write-Host 'Not a git repository.'
}