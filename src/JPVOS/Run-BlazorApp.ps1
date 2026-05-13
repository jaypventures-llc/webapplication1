$ErrorActionPreference = "Stop"

$Project = Split-Path -Parent $MyInvocation.MyCommand.Path
$Url = "http://localhost:5111"
$Log = Join-Path $Project "dotnet_run.log"

taskkill /IM dotnet.exe /F 2>$null

Set-Location $Project

Remove-Item .\bin,.\obj -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $Log -Force -ErrorAction SilentlyContinue

dotnet restore
dotnet build

$env:ASPNETCORE_URLS = $Url

$Process = Start-Process dotnet `
    -ArgumentList "run --no-build" `
    -WorkingDirectory $Project `
    -RedirectStandardOutput $Log `
    -PassThru

Start-Sleep -Seconds 5

$Output = Get-Content $Log -Raw -ErrorAction SilentlyContinue

if ($Output -match "Now listening on:\s*(http://localhost:\d+)") {
    $DetectedUrl = $Matches[1]
    Write-Host "APP ONLINE: $DetectedUrl" -ForegroundColor Green
    Start-Process $DetectedUrl
} else {
    Write-Host "APP DID NOT START. LOG OUTPUT:" -ForegroundColor Red
    Get-Content $Log
    Stop-Process $Process.Id -Force -ErrorAction SilentlyContinue
    exit 1
}
