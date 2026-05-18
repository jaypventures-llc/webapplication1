param(
  [Parameter(Mandatory = $true)][string]$GitHubUsername,
  [Parameter(Mandatory = $true)][string]$PersonalAccessToken,
  [Parameter(Mandatory = $true)][string]$Owner,
  [Parameter(Mandatory = $true)][string]$Repo,
  [Parameter(Mandatory = $true)][string]$Branch
)

$ErrorActionPreference = "Stop"

$originalUrl = git remote get-url origin
$newUrl = "https://github.com/$Owner/$Repo.git"
$askPassBasePath = [System.IO.Path]::GetTempFileName()
$askPassPath = [System.IO.Path]::ChangeExtension($askPassBasePath, ".cmd")
Move-Item -Path $askPassBasePath -Destination $askPassPath -Force

@'
@echo off
if /I "%1"=="Username for 'https://github.com': " (
  echo %GIT_ASKPASS_USERNAME%
) else (
  echo %GIT_ASKPASS_PASSWORD%
)
'@ | Set-Content -Path $askPassPath -NoNewline

$previousAskPass = $env:GIT_ASKPASS
$previousAskPassUsername = $env:GIT_ASKPASS_USERNAME
$previousAskPassPassword = $env:GIT_ASKPASS_PASSWORD
$previousTerminalPrompt = $env:GIT_TERMINAL_PROMPT

try {
  $env:GIT_ASKPASS = $askPassPath
  $env:GIT_ASKPASS_USERNAME = $GitHubUsername
  $env:GIT_ASKPASS_PASSWORD = $PersonalAccessToken
  $env:GIT_TERMINAL_PROMPT = "0"

  Write-Host "Temporarily setting remote URL..."
  git remote set-url origin $newUrl

  Write-Host "Pushing branch $Branch..."
  git push --set-upstream origin $Branch
}
finally {
  Write-Host "Restoring original remote URL..."
  git remote set-url origin $originalUrl

  if ($null -ne $previousAskPass) {
    $env:GIT_ASKPASS = $previousAskPass
  } else {
    Remove-Item Env:GIT_ASKPASS -ErrorAction SilentlyContinue
  }

  if ($null -ne $previousAskPassUsername) {
    $env:GIT_ASKPASS_USERNAME = $previousAskPassUsername
  } else {
    Remove-Item Env:GIT_ASKPASS_USERNAME -ErrorAction SilentlyContinue
  }

  if ($null -ne $previousAskPassPassword) {
    $env:GIT_ASKPASS_PASSWORD = $previousAskPassPassword
  } else {
    Remove-Item Env:GIT_ASKPASS_PASSWORD -ErrorAction SilentlyContinue
  }

  if ($null -ne $previousTerminalPrompt) {
    $env:GIT_TERMINAL_PROMPT = $previousTerminalPrompt
  } else {
    Remove-Item Env:GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
  }

  Remove-Item -Path $askPassPath -Force -ErrorAction SilentlyContinue
}

Write-Host "Done."
