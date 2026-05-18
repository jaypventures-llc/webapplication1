$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-jpv-os-access-gateway"
$WebAppName = "jpv-os-access-gateway"
$BaseUrl = "https://jpv-os-access-gateway.azurewebsites.net"

Write-Host ""
Write-Host "======================================"
Write-Host "STRIPE TEST VALIDATION"
Write-Host "======================================"

Write-Host ""
Write-Host "[1] Checking Azure Stripe app settings..."

$Settings = az webapp config appsettings list `
  --resource-group $ResourceGroup `
  --name $WebAppName `
  -o json | ConvertFrom-Json

$StripeSettings = $Settings |
  Where-Object { $_.name -match "STRIPE" } |
  Select-Object -ExpandProperty name

$StripeSettings

if ($StripeSettings -notcontains "STRIPE_SECRET_KEY") {
    throw "Missing STRIPE_SECRET_KEY app setting."
}

if ($StripeSettings -notcontains "STRIPE_WEBHOOK_SECRET") {
    throw "Missing STRIPE_WEBHOOK_SECRET app setting."
}

Write-Host ""
Write-Host "[2] Restarting Azure Web App..."

az webapp restart `
  --resource-group $ResourceGroup `
  --name $WebAppName `
  --output none

Start-Sleep -Seconds 15

Write-Host ""
Write-Host "[3] Checking /api/health..."

$Health = Invoke-RestMethod "$BaseUrl/api/health"

if ($Health.status -ne "healthy") {
    throw "Health endpoint failed."
}

Write-Host "Health passed."

Write-Host ""
Write-Host "[4] Validating Stripe webhook fail-closed behavior..."

try {
    Invoke-WebRequest `
      "$BaseUrl/api/stripe/webhook" `
      -Method POST `
      -ContentType "application/json" `
      -Body "{}" `
      -UseBasicParsing `
      -ErrorAction Stop | Out-Null

    throw "Webhook incorrectly accepted unsigned payload."
}
catch {
    $StatusCode = $_.Exception.Response.StatusCode.value__

    if ($StatusCode -in 400,401,403) {
        Write-Host "Webhook fail-closed passed with HTTP $StatusCode."
    }
    elseif ($StatusCode -eq 404) {
        throw "Webhook endpoint returned 404."
    }
    else {
        throw "Unexpected webhook response: HTTP $StatusCode"
    }
}

Write-Host ""
Write-Host "[5] Running runtime verification..."

.\scripts\verify-runtime.ps1

Write-Host ""
Write-Host "======================================"
Write-Host "STRIPE VALIDATION COMPLETE"
Write-Host "======================================"
