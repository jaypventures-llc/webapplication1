$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-jpv-os-access-gateway"
$WebAppName = "jpv-os-access-gateway"
$BaseUrl = "https://jpv-os-access-gateway.azurewebsites.net"

$Required = @(
    @{ Key="STRIPE_PRICE_MEMBER_MONTHLY"; Label="Member Access - $10 monthly" },
    @{ Key="STRIPE_PRICE_MEMBER_ANNUAL"; Label="Member Access - $100 yearly" },
    @{ Key="STRIPE_PRICE_VIP_MONTHLY"; Label="VIP Venture - $30 monthly" },
    @{ Key="STRIPE_PRICE_VIP_ANNUAL"; Label="VIP Venture - $300 yearly" },
    @{ Key="STRIPE_PRICE_CREATOR_LANE_MONTHLY"; Label="Creator Lane - $80 monthly" },
    @{ Key="STRIPE_PRICE_OPERATOR_MONTHLY"; Label="Operator - $250 monthly" },
    @{ Key="STRIPE_PRICE_ENTERPRISE_MONTHLY"; Label="Enterprise - $900 monthly" }
)

function Read-RealStripePriceId {
    param([string]$Label)

    do {
        $Value = Read-Host "Paste REAL TEST Price ID for $Label"

        if ($Value -notmatch "^price_[A-Za-z0-9_]+$") {
            Write-Host "Invalid. It must be a real Stripe Price API ID beginning with lowercase price_"
            Write-Host "Example format: price_1Rxxxxxxxxxxxxxxxxxxxx"
        }
    } until ($Value -match "^price_[A-Za-z0-9_]+$")

    return $Value.Trim()
}

Write-Host ""
Write-Host "======================================"
Write-Host "STRIPE DASHBOARD-ASSISTED SETUP"
Write-Host "======================================"
Write-Host ""
Write-Host "This does not require winget or Stripe CLI."
Write-Host "You must copy actual Price API IDs from Stripe Test mode."
Write-Host ""
Write-Host "Do NOT enter:"
Write-Host "- Price_10"
Write-Host "- price_100"
Write-Host "- 900"
Write-Host "- prod_..."
Write-Host ""
Write-Host "Only enter real generated IDs like:"
Write-Host "price_1Rxxxxxxxxxxxxxxxxxxxx"
Write-Host ""

Start-Process "https://dashboard.stripe.com/test/products"

$PriceMap = @{}

foreach ($Item in $Required) {
    $PriceMap[$Item.Key] = Read-RealStripePriceId $Item.Label
}

$PriceMap["STRIPE_PRICE_ID_COMMUNITY"] = $PriceMap["STRIPE_PRICE_MEMBER_MONTHLY"]
$PriceMap["STRIPE_PRICE_ID_VIP"] = $PriceMap["STRIPE_PRICE_VIP_MONTHLY"]
$PriceMap["STRIPE_PRICE_ENTERPRISE_ANNUAL"] = $PriceMap["STRIPE_PRICE_ENTERPRISE_MONTHLY"]
$PriceMap["STRIPE_PRICE_CUSTOM_IMPLEMENTATION"] = $PriceMap["STRIPE_PRICE_OPERATOR_MONTHLY"]

$AzureSettings = @(
    "PUBLIC_APP_BASE_URL=$BaseUrl",
    "STRIPE_AUTOMATIC_TAX_ENABLED=false"
)

foreach ($Pair in $PriceMap.GetEnumerator()) {
    $AzureSettings += "$($Pair.Key)=$($Pair.Value)"
}

Write-Host ""
Write-Host "Applying settings to Azure App Service..."

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $WebAppName `
    --settings $AzureSettings `
    --output none

Write-Host ""
Write-Host "Restarting Azure Web App..."

az webapp restart `
    --resource-group $ResourceGroup `
    --name $WebAppName `
    --output none

Start-Sleep -Seconds 15

Write-Host ""
Write-Host "Verifying configured setting names only..."

$Settings = az webapp config appsettings list `
    --resource-group $ResourceGroup `
    --name $WebAppName `
    -o json | ConvertFrom-Json

$Settings |
    Where-Object { $_.name -match "STRIPE_PRICE|PUBLIC_APP_BASE_URL|STRIPE_AUTOMATIC_TAX|STRIPE_SECRET|STRIPE_WEBHOOK" } |
    Select-Object name |
    Sort-Object name |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Checking app health..."

Invoke-WebRequest "$BaseUrl/api/health" -UseBasicParsing |
    Select-Object StatusCode,StatusDescription

Write-Host ""
Write-Host "Opening pricing page..."

Start-Process "$BaseUrl/pricing?v=$(Get-Date -Format yyyyMMddHHmmss)"

Write-Host ""
Write-Host "======================================"
Write-Host "STRIPE PRICE CONFIG COMPLETE"
Write-Host "======================================"
Write-Host ""
Write-Host "Test card:"
Write-Host "4242 4242 4242 4242"
Write-Host "Any future date, any CVC, any ZIP."
