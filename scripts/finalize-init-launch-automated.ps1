$ErrorActionPreference = "Stop"

$RepoRoot = "C:\Users\jaypv\JPV-OS-Workspace\01-Active-Apps\jpv-os-access-gateway"
$AppRoot  = Join-Path $RepoRoot "src\JPVOS"
$ApprovedUrl = "http://localhost:5111"

function Step($m){ Write-Host "`n== $m ==" -ForegroundColor Cyan }
function OK($m){ Write-Host "OK: $m" -ForegroundColor Green }
function Warn($m){ Write-Host "WARN: $m" -ForegroundColor Yellow }
function Fail($m){ throw "FAILED: $m" }

if (!(Test-Path $AppRoot)) { Fail "App root not found: $AppRoot" }
Set-Location $AppRoot

Step "Stopping preview drift"
Get-NetTCPConnection -LocalPort 4173,4174,1455,5111 -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.OwningProcess) {
        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
    }
}
Get-Process dotnet,node,vite,python,python3 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
OK "Stopped old preview processes"

Step "Checking dotnet"
if (!(Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Fail "dotnet is not available in this PowerShell session"
}
dotnet --info | Out-Host

Step "Setting known non-secret launch variables"
[Environment]::SetEnvironmentVariable("STRIPE_PRICE_ID_COMMUNITY","price_1TJkCqBClaNmyr4zF30Mqnw0","User")
[Environment]::SetEnvironmentVariable("STRIPE_PRICE_ID_VIP","price_1TJkDDBClaNmyr4zhaFK1eSR","User")
[Environment]::SetEnvironmentVariable("DISCORD_CLIENT_ID","1468076818266456186","User")
OK "Known non-secret variables set"

function Set-SecretEnv($Name, $Prompt) {
    $existing = [Environment]::GetEnvironmentVariable($Name, "User")
    if (![string]::IsNullOrWhiteSpace($existing)) {
        OK "$Name already exists"
        return
    }

    $secure = Read-Host $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    if ([string]::IsNullOrWhiteSpace($plain)) {
        Fail "$Name is required"
    }

    [Environment]::SetEnvironmentVariable($Name, $plain, "User")
    OK "$Name saved to user environment"
}

Step "Collecting required secrets safely"
Set-SecretEnv "STRIPE_SECRET_KEY" "Paste Stripe secret key"
Set-SecretEnv "STRIPE_WEBHOOK_SECRET" "Paste Stripe webhook signing secret"
Set-SecretEnv "DISCORD_CLIENT_SECRET" "Paste Discord client secret"
Set-SecretEnv "DISCORD_BOT_TOKEN" "Paste Discord bot token"
Set-SecretEnv "DISCORD_GUILD_ID" "Paste Discord guild/server ID"
Set-SecretEnv "DISCORD_ROLE_COMMUNITY_ID" "Paste Discord Community role ID"
Set-SecretEnv "DISCORD_ROLE_VIP_ID" "Paste Discord VIP role ID"

Step "Ensuring package references"
$Csproj = Join-Path $AppRoot "JPVOS.csproj"
if (!(Test-Path $Csproj)) { Fail "Missing JPVOS.csproj" }

$xml = Get-Content $Csproj -Raw
$packages = @(
    @{Name="Stripe.net"; Version="46.2.0"},
    @{Name="Dapper"; Version="2.1.66"},
    @{Name="Microsoft.Data.Sqlite"; Version="9.0.8"}
)

foreach ($pkg in $packages) {
    if ($xml -notmatch "Include=`"$($pkg.Name)`"") {
        $insert = "  <ItemGroup>`r`n    <PackageReference Include=`"$($pkg.Name)`" Version=`"$($pkg.Version)`" />`r`n  </ItemGroup>`r`n"
        $xml = $xml -replace "</Project>", "$insert</Project>"
        OK "Added $($pkg.Name)"
    }
}
Set-Content $Csproj $xml -Encoding UTF8

Step "Ensuring launch CSS is referenced"
$AppRazor = Join-Path $AppRoot "Components\App.razor"
if (Test-Path $AppRazor) {
    $content = Get-Content $AppRazor -Raw
    if ($content -notmatch "init-system.css") {
        $content = $content -replace "</head>", "    <link rel=`"stylesheet`" href=`"css/init-system.css`" />`r`n</head>"
        Set-Content $AppRazor $content -Encoding UTF8
        OK "Linked css/init-system.css"
    }
}

Step "Creating launch verification script"
$VerifyPath = Join-Path $RepoRoot "scripts\verify-init-launch.ps1"

@"
`$ErrorActionPreference = "Stop"
`$RepoRoot = "$RepoRoot"
`$AppRoot = "$AppRoot"
Set-Location `$AppRoot

Write-Host "`n== Required file check ==" -ForegroundColor Cyan
`$requiredFiles = @(
  "Components\Pages\Pricing.razor",
  "Api\CheckoutController.cs",
  "Api\CheckoutConfigStatusController.cs",
  "Services\DiscordService.cs",
  "Components\Pages\Home.razor",
  "wwwroot\css\init-system.css"
)
foreach (`$f in `$requiredFiles) {
  if (!(Test-Path `$f)) { throw "Missing required file: `$f" }
  Write-Host "OK: `$f" -ForegroundColor Green
}

Write-Host "`n== Stale text search ==" -ForegroundColor Cyan
`$stale = Select-String -Path ".\**\*.*" -Pattern "Checkout Setup|Checkout is being configured|STRIPE_PRICE_MEMBER_MONTHLY|STRIPE_PRICE_CREATOR_MONTHLY|DISCORD_ROLE_MEMBER|DISCORD_ROLE_CREATOR" -ErrorAction SilentlyContinue
if (`$stale) {
  `$stale | ForEach-Object { Write-Host "`$(`$_.Path):`$(`$_.LineNumber) `$(`$_.Line)" -ForegroundColor Yellow }
  throw "Stale launch references found"
}
Write-Host "OK: no stale checkout/setup references found" -ForegroundColor Green

Write-Host "`n== Secret pattern scan ==" -ForegroundColor Cyan
`$secretHits = Select-String -Path ".\**\*.cs",".\**\*.razor",".\**\*.json",".\**\*.md",".\**\*.ps1" -Pattern "sk_live_|sk_test_|whsec_|DISCORD_BOT_TOKEN\s*=\s*\S+|DISCORD_CLIENT_SECRET\s*=\s*\S+" -ErrorAction SilentlyContinue
if (`$secretHits) {
  `$secretHits | ForEach-Object { Write-Host "`$(`$_.Path):`$(`$_.LineNumber)" -ForegroundColor Red }
  throw "Possible secret committed to repo"
}
Write-Host "OK: no obvious committed secrets found" -ForegroundColor Green

Write-Host "`n== Environment variable check ==" -ForegroundColor Cyan
`$requiredEnv = @(
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
foreach (`$name in `$requiredEnv) {
  `$value = [Environment]::GetEnvironmentVariable(`$name, "User")
  if ([string]::IsNullOrWhiteSpace(`$value)) { throw "Missing user environment variable: `$name" }
  Write-Host "OK: `$name is set" -ForegroundColor Green
}

Write-Host "`n== Build ==" -ForegroundColor Cyan
dotnet restore
if (`$LASTEXITCODE -ne 0) { throw "dotnet restore failed" }

dotnet build
if (`$LASTEXITCODE -ne 0) { throw "dotnet build failed" }

Write-Host "`nLaunch verification passed." -ForegroundColor Green
"@ | Set-Content $VerifyPath -Encoding UTF8

OK "Created $VerifyPath"

Step "Running restore/build"
dotnet restore
if ($LASTEXITCODE -ne 0) { Fail "dotnet restore failed" }

dotnet build
if ($LASTEXITCODE -ne 0) { Fail "dotnet build failed" }

OK "Build passed"

Step "Starting app on localhost:5111"
Start-Process powershell -ArgumentList "-NoExit","-Command","cd `"$AppRoot`"; dotnet run --no-launch-profile --urls `"$ApprovedUrl`""
Start-Sleep -Seconds 4

Start-Process $ApprovedUrl
Start-Process "$ApprovedUrl/api/checkout/config-status"

Write-Host "`nDONE." -ForegroundColor Green
Write-Host "Use only: $ApprovedUrl"
Write-Host "Verification script: $VerifyPath"
