param([string]$ReportPath = "reports/discord-env-validation.md")

$ErrorActionPreference = "Stop"

$required = @(
    "STRIPE_SECRET_KEY",
    "STRIPE_WEBHOOK_SECRET",
    "DISCORD_GUILD_ID",
    "DISCORD_BOT_TOKEN",
    "DISCORD_CLIENT_ID",
    "DISCORD_CLIENT_SECRET",
    "DISCORD_REDIRECT_URI",
    "DISCORD_ROLE_MEMBER_ACCESS",
    "DISCORD_ROLE_VIP_VENTURE",
    "DISCORD_ROLE_CREATOR_LANE",
    "DISCORD_ROLE_OPERATOR",
    "DISCORD_ROLE_ENTERPRISE"
)

$reportDir = Split-Path -Parent $ReportPath
if ($reportDir) {
    New-Item -ItemType Directory -Force $reportDir | Out-Null
}

$missing = @()

"# Discord / Stripe Environment Validation" | Set-Content $ReportPath
"" | Add-Content $ReportPath
"Generated: $(Get-Date -Format o)" | Add-Content $ReportPath
"" | Add-Content $ReportPath
"## Required Settings" | Add-Content $ReportPath
"" | Add-Content $ReportPath

foreach ($key in $required) {
    $value = [Environment]::GetEnvironmentVariable($key)

    if ([string]::IsNullOrWhiteSpace($value)) {
        $missing += $key
        "- $key : MISSING" | Add-Content $ReportPath
        Write-Host "MISSING: $key"
    }
    else {
        "- $key : SET" | Add-Content $ReportPath
        Write-Host "SET: $key"
    }
}

"" | Add-Content $ReportPath
"## Result" | Add-Content $ReportPath
"" | Add-Content $ReportPath

if ($missing.Count -gt 0) {
    "FAILED: Missing $($missing.Count) required setting(s)." | Add-Content $ReportPath
    "" | Add-Content $ReportPath
    "Missing:" | Add-Content $ReportPath
    foreach ($key in $missing) {
        "- $key" | Add-Content $ReportPath
    }

    exit 1
}

"PASSED: All required settings are present." | Add-Content $ReportPath
exit 0

