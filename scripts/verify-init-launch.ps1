$ErrorActionPreference = "Stop"
$RepoRoot = "C:\Users\jaypv\JPV-OS-Workspace\01-Active-Apps\jpv-os-access-gateway"
$AppRoot = "C:\Users\jaypv\JPV-OS-Workspace\01-Active-Apps\jpv-os-access-gateway\src\JPVOS"
Set-Location $AppRoot

Write-Host "
== Required file check ==" -ForegroundColor Cyan
$requiredFiles = @(
  "Components\Pages\Pricing.razor",
  "Api\CheckoutController.cs",
  "Api\CheckoutConfigStatusController.cs",
  "Services\DiscordService.cs",
  "Components\Pages\Home.razor",
  "wwwroot\css\init-system.css"
)
foreach ($f in $requiredFiles) {
  if (!(Test-Path $f)) { throw "Missing required file: $f" }
  Write-Host "OK: $f" -ForegroundColor Green
}

Write-Host "
== Stale text search ==" -ForegroundColor Cyan
$stale = Select-String -Path ".\**\*.*" -Pattern "Checkout Setup|Checkout is being configured|STRIPE_PRICE_MEMBER_MONTHLY|STRIPE_PRICE_CREATOR_MONTHLY|DISCORD_ROLE_MEMBER|DISCORD_ROLE_CREATOR" -ErrorAction SilentlyContinue
if ($stale) {
  $stale | ForEach-Object { Write-Host "$($_.Path):$($_.LineNumber) $($_.Line)" -ForegroundColor Yellow }
  throw "Stale launch references found"
}
Write-Host "OK: no stale checkout/setup references found" -ForegroundColor Green

Write-Host "
== Secret pattern scan ==" -ForegroundColor Cyan
$secretHits = Select-String -Path ".\**\*.cs",".\**\*.razor",".\**\*.json",".\**\*.md",".\**\*.ps1" -Pattern "sk_live_|sk_test_|whsec_|DISCORD_BOT_TOKEN\s*=\s*\S+|DISCORD_CLIENT_SECRET\s*=\s*\S+" -ErrorAction SilentlyContinue
if ($secretHits) {
  $secretHits | ForEach-Object { Write-Host "$($_.Path):$($_.LineNumber)" -ForegroundColor Red }
  throw "Possible secret committed to repo"
}
Write-Host "OK: no obvious committed secrets found" -ForegroundColor Green

Write-Host "
== Environment variable check ==" -ForegroundColor Cyan
$requiredEnv = @(
  "STRIPE_SECRET_KEY",
  "STRIPE_WEBHOOK_SECRET",
  "STRIPE_PRICE_ID_COMMUNITY",
  "STRIPE_PRICE_ID_VIP",
  "DISCORD_CLIENT_ID",
  "DISCORD_CLIENT_SECRET",
  "DISCORD_BOT_TOKEN",
  "DISCORD_GUILD_ID",
  "DISCORD_ROLE_COMMUNITY_ID",
  "DISCORD_ROLE_VIP_ID"
)
foreach ($name in $requiredEnv) {
  $value = [Environment]::GetEnvironmentVariable($name, "User")
  if ([string]::IsNullOrWhiteSpace($value)) { throw "Missing user environment variable: $name" }
  Write-Host "OK: $name is set" -ForegroundColor Green
}

Write-Host "
== Build ==" -ForegroundColor Cyan
dotnet restore
if ($LASTEXITCODE -ne 0) { throw "dotnet restore failed" }

dotnet build
if ($LASTEXITCODE -ne 0) { throw "dotnet build failed" }

Write-Host "
Launch verification passed." -ForegroundColor Green
