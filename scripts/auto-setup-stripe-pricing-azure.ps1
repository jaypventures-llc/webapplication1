$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-jpv-os-access-gateway"
$WebAppName = "jpv-os-access-gateway"
$BaseUrl = "https://jpv-os-access-gateway.azurewebsites.net"

$Plans = @(
    @{ Key="STRIPE_PRICE_MEMBER_MONTHLY"; LegacyKey="STRIPE_PRICE_ID_COMMUNITY"; Name="Member Access"; Amount=1000; Interval="month" },
    @{ Key="STRIPE_PRICE_MEMBER_ANNUAL"; LegacyKey=$null; Name="Member Access"; Amount=10000; Interval="year" },
    @{ Key="STRIPE_PRICE_VIP_MONTHLY"; LegacyKey="STRIPE_PRICE_ID_VIP"; Name="VIP Venture"; Amount=3000; Interval="month" },
    @{ Key="STRIPE_PRICE_VIP_ANNUAL"; LegacyKey=$null; Name="VIP Venture"; Amount=30000; Interval="year" },
    @{ Key="STRIPE_PRICE_CREATOR_LANE_MONTHLY"; LegacyKey=$null; Name="Creator Lane"; Amount=8000; Interval="month" },
    @{ Key="STRIPE_PRICE_OPERATOR_MONTHLY"; LegacyKey="STRIPE_PRICE_CUSTOM_IMPLEMENTATION"; Name="Operator"; Amount=25000; Interval="month" },
    @{ Key="STRIPE_PRICE_ENTERPRISE_MONTHLY"; LegacyKey="STRIPE_PRICE_ENTERPRISE_ANNUAL"; Name="Enterprise"; Amount=90000; Interval="month" }
)

function Test-StripeCliReady {
    $stripe = Get-Command stripe -ErrorAction SilentlyContinue
    if (-not $stripe) {
        return $false
    }

    try {
        stripe balance retrieve --format json | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Read-PriceId {
    param([string]$Label)

    do {
        $Value = Read-Host "Paste TEST Stripe Price ID for $Label"
        if ($Value -notmatch "^price_") {
            Write-Host "Invalid. Price IDs must start with price_"
        }
    } until ($Value -match "^price_")

    return $Value.Trim()
}

Write-Host ""
Write-Host "======================================"
Write-Host "FULL STRIPE PRICING + AZURE SETUP"
Write-Host "======================================"

Write-Host ""
Write-Host "This configures:"
Write-Host "- Member Access: $10/mo and $100/yr"
Write-Host "- VIP Venture: $30/mo and $300/yr"
Write-Host "- Creator Lane: $80/mo"
Write-Host "- Operator: $250/mo"
Write-Host "- Enterprise: $900/mo"
Write-Host "- Sovereign: custom/contact only"
Write-Host ""

$PriceMap = @{}
$StripeCliReady = Test-StripeCliReady

if ($StripeCliReady) {
    Write-Host "Stripe CLI detected and authenticated."
    $UseCli = Read-Host "Type YES to auto-create TEST products/prices with Stripe CLI"

    if ($UseCli -eq "YES") {
        foreach ($Plan in $Plans) {
            Write-Host ""
            Write-Host "Creating or locating product: $($Plan.Name)"

            $ProductJson = stripe products create `
                --name "$($Plan.Name)" `
                --description "JPV-OS Access Gateway - $($Plan.Name)" `
                --format json | ConvertFrom-Json

            if (-not $ProductJson.id -or $ProductJson.id -notmatch "^prod_") {
                throw "Failed to create Stripe product for $($Plan.Name)"
            }

            Write-Host "Creating price for $($Plan.Name) $($Plan.Interval)"

            $PriceJson = stripe prices create `
                --currency usd `
                --unit-amount $Plan.Amount `
                --recurring.interval $Plan.Interval `
                --product $ProductJson.id `
                --format json | ConvertFrom-Json

            if (-not $PriceJson.id -or $PriceJson.id -notmatch "^price_") {
                throw "Failed to create Stripe price for $($Plan.Name)"
            }

            $PriceMap[$Plan.Key] = $PriceJson.id

            if ($Plan.LegacyKey) {
                $PriceMap[$Plan.LegacyKey] = $PriceJson.id
            }

            Write-Host "Created $($Plan.Key)"
        }
    }
}

if ($PriceMap.Count -eq 0) {
    Write-Host ""
    Write-Host "Stripe CLI is not available or was not selected."
    Write-Host "Opening Stripe TEST product catalog."
    Write-Host "Create or locate the prices, then paste the Price IDs."
    Write-Host ""

    Start-Process "https://dashboard.stripe.com/test/products"

    foreach ($Plan in $Plans) {
        $Label = "$($Plan.Name) - $($Plan.Amount / 100) USD / $($Plan.Interval)"
        $PriceId = Read-PriceId $Label

        $PriceMap[$Plan.Key] = $PriceId

        if ($Plan.LegacyKey) {
            $PriceMap[$Plan.LegacyKey] = $PriceId
        }
    }
}

Write-Host ""
Write-Host "Setting Azure App Service configuration..."

$AzureSettings = @(
    "PUBLIC_APP_BASE_URL=$BaseUrl",
    "STRIPE_AUTOMATIC_TAX_ENABLED=false"
)

foreach ($Pair in $PriceMap.GetEnumerator()) {
    $AzureSettings += "$($Pair.Key)=$($Pair.Value)"
}

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
Write-Host "Verifying Stripe setting names only..."

$Settings = az webapp config appsettings list `
    --resource-group $ResourceGroup `
    --name $WebAppName `
    -o json | ConvertFrom-Json

$Settings |
    Where-Object { $_.name -match "STRIPE_PRICE|STRIPE_SECRET|STRIPE_WEBHOOK|PUBLIC_APP_BASE_URL|STRIPE_AUTOMATIC_TAX" } |
    Select-Object name |
    Sort-Object name |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Checking checkout config status..."

try {
    Invoke-WebRequest "$BaseUrl/api/checkout/config-status" -UseBasicParsing |
        Select-Object StatusCode,StatusDescription,Content
}
catch {
    Write-Host "Checkout config status failed:"
    Write-Host $_.Exception.Message
}

Write-Host ""
Write-Host "Checking health..."

Invoke-WebRequest "$BaseUrl/api/health" -UseBasicParsing |
    Select-Object StatusCode,StatusDescription

Write-Host ""
Write-Host "Opening pricing page..."

Start-Process "$BaseUrl/pricing?v=$(Get-Date -Format yyyyMMddHHmmss)"

Write-Host ""
Write-Host "======================================"
Write-Host "STRIPE PRICING SETUP COMPLETE"
Write-Host "======================================"
Write-Host ""
Write-Host "Test checkout with:"
Write-Host "4242 4242 4242 4242"
Write-Host "Any future date, any CVC, any ZIP."
