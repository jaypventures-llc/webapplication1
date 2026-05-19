$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-jpv-os-access-gateway"
$WebAppName = "jpv-os-access-gateway"
$BaseUrl = "https://jpv-os-access-gateway.azurewebsites.net"

$Plans = @(
    @{ Key="STRIPE_PRICE_MEMBER_MONTHLY"; LegacyKey="STRIPE_PRICE_ID_COMMUNITY"; Product="Member Access"; Nickname="Member Access Monthly"; Amount=1000; Interval="month" },
    @{ Key="STRIPE_PRICE_MEMBER_ANNUAL"; LegacyKey=$null; Product="Member Access"; Nickname="Member Access Annual"; Amount=10000; Interval="year" },
    @{ Key="STRIPE_PRICE_VIP_MONTHLY"; LegacyKey="STRIPE_PRICE_ID_VIP"; Product="VIP Venture"; Nickname="VIP Venture Monthly"; Amount=3000; Interval="month" },
    @{ Key="STRIPE_PRICE_VIP_ANNUAL"; LegacyKey=$null; Product="VIP Venture"; Nickname="VIP Venture Annual"; Amount=30000; Interval="year" },
    @{ Key="STRIPE_PRICE_CREATOR_LANE_MONTHLY"; LegacyKey=$null; Product="Creator Lane"; Nickname="Creator Lane Monthly"; Amount=8000; Interval="month" },
    @{ Key="STRIPE_PRICE_OPERATOR_MONTHLY"; LegacyKey="STRIPE_PRICE_CUSTOM_IMPLEMENTATION"; Product="Operator"; Nickname="Operator Monthly"; Amount=25000; Interval="month" },
    @{ Key="STRIPE_PRICE_ENTERPRISE_MONTHLY"; LegacyKey="STRIPE_PRICE_ENTERPRISE_ANNUAL"; Product="Enterprise"; Nickname="Enterprise Monthly"; Amount=90000; Interval="month" }
)

function Ensure-StripeCli {
    $Stripe = Get-Command stripe -ErrorAction SilentlyContinue

    if ($Stripe) {
        Write-Host "Stripe CLI found."
        return
    }

    Write-Host "Stripe CLI not found. Installing with winget..."
    winget install Stripe.StripeCLI --accept-source-agreements --accept-package-agreements

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    $Stripe = Get-Command stripe -ErrorAction SilentlyContinue
    if (-not $Stripe) {
        throw "Stripe CLI install completed but stripe command is still unavailable. Restart PowerShell and rerun this script."
    }
}

function Ensure-StripeLogin {
    Write-Host "Checking Stripe CLI authentication..."

    try {
        stripe balance retrieve --format json | Out-Null
        Write-Host "Stripe CLI is authenticated."
    }
    catch {
        Write-Host "Stripe CLI is not authenticated. Opening Stripe login..."
        stripe login

        Write-Host "Rechecking Stripe CLI authentication..."
        stripe balance retrieve --format json | Out-Null
    }
}

function New-StripeProduct {
    param([string]$Name)

    Write-Host "Creating Stripe test product: $Name"

    $Json = stripe products create `
        --name "$Name" `
        --description "JPV-OS Access Gateway - $Name" `
        --format json | ConvertFrom-Json

    if (-not $Json.id -or $Json.id -notmatch "^prod_") {
        throw "Failed to create product: $Name"
    }

    return $Json.id
}

function New-StripePrice {
    param(
        [string]$ProductId,
        [string]$Nickname,
        [int]$Amount,
        [string]$Interval
    )

    Write-Host "Creating Stripe test price: $Nickname"

    $Json = stripe prices create `
        --currency usd `
        --unit-amount $Amount `
        --recurring.interval $Interval `
        --product $ProductId `
        --nickname "$Nickname" `
        --format json | ConvertFrom-Json

    if (-not $Json.id -or $Json.id -notmatch "^price_") {
        throw "Failed to create price: $Nickname"
    }

    return $Json.id
}

Write-Host ""
Write-Host "======================================"
Write-Host "FULL STRIPE PRODUCT + AZURE AUTOMATION"
Write-Host "======================================"
Write-Host ""

Write-Host "This will create TEST-mode Stripe products/prices:"
Write-Host "- Member Access: $10/mo and $100/yr"
Write-Host "- VIP Venture: $30/mo and $300/yr"
Write-Host "- Creator Lane: $80/mo"
Write-Host "- Operator: $250/mo"
Write-Host "- Enterprise: $900/mo"
Write-Host ""
Write-Host "Sovereign remains custom/contact only."
Write-Host "Automatic tax will remain disabled."
Write-Host ""

$Confirm = Read-Host "Type YES to proceed"
if ($Confirm -ne "YES") {
    throw "Cancelled."
}

Ensure-StripeCli
Ensure-StripeLogin

$Products = @{}
$PriceSettings = @{}

foreach ($Plan in $Plans) {
    if (-not $Products.ContainsKey($Plan.Product)) {
        $Products[$Plan.Product] = New-StripeProduct -Name $Plan.Product
    }

    $PriceId = New-StripePrice `
        -ProductId $Products[$Plan.Product] `
        -Nickname $Plan.Nickname `
        -Amount $Plan.Amount `
        -Interval $Plan.Interval

    $PriceSettings[$Plan.Key] = $PriceId

    if ($Plan.LegacyKey) {
        $PriceSettings[$Plan.LegacyKey] = $PriceId
    }
}

Write-Host ""
Write-Host "Applying Stripe Price IDs to Azure App Service..."

$AzureSettings = @(
    "PUBLIC_APP_BASE_URL=$BaseUrl",
    "STRIPE_AUTOMATIC_TAX_ENABLED=false"
)

foreach ($Pair in $PriceSettings.GetEnumerator()) {
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
Write-Host "Verifying Stripe/Azure setting names only..."

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
Write-Host "Checking health..."

Invoke-WebRequest "$BaseUrl/api/health" -UseBasicParsing |
    Select-Object StatusCode,StatusDescription

Write-Host ""
Write-Host "Opening Stripe Dashboard product catalog..."
Start-Process "https://dashboard.stripe.com/test/products"

Write-Host ""
Write-Host "Opening pricing page..."
Start-Process "$BaseUrl/pricing?v=$(Get-Date -Format yyyyMMddHHmmss)"

Write-Host ""
Write-Host "======================================"
Write-Host "STRIPE PRODUCT + AZURE SETUP COMPLETE"
Write-Host "======================================"
Write-Host ""
Write-Host "Test checkout with:"
Write-Host "4242 4242 4242 4242"
Write-Host "Any future expiration, any CVC, any ZIP."
