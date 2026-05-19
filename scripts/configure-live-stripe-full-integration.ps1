$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-jpv-os-access-gateway"
$WebAppName = "jpv-os-access-gateway"
$BaseUrl = "https://jpv-os-access-gateway.azurewebsites.net"
$PublicSite = "https://jaypventuresllc.com"

function Read-Required {
    param(
        [string]$Prompt,
        [string]$Pattern,
        [string]$Example
    )

    do {
        $Value = Read-Host $Prompt

        if ($Value -notmatch $Pattern) {
            Write-Host ""
            Write-Host "Invalid value."
            Write-Host "Expected example: $Example"
            Write-Host ""
        }
    } until ($Value -match $Pattern)

    return $Value.Trim()
}

Write-Host ""
Write-Host "======================================"
Write-Host "JPV LIVE STRIPE FULL INTEGRATION"
Write-Host "======================================"
Write-Host ""
Write-Host "This configures LIVE Stripe values in Azure App Service."
Write-Host "Do not paste test keys."
Write-Host "Do not paste fake values like Price_10 or price_100."
Write-Host ""
Write-Host "Required live values:"
Write-Host "- sk_live_..."
Write-Host "- whsec_..."
Write-Host "- live price_... IDs from Stripe LIVE mode"
Write-Host ""
Write-Host "Automatic tax will remain disabled until Stripe Tax is fully verified."
Write-Host ""

$Confirm = Read-Host "Type LIVE to continue"
if ($Confirm -ne "LIVE") {
    throw "Cancelled. You must type LIVE exactly."
}

Write-Host ""
Write-Host "[1] Opening required Stripe pages..."

Start-Process "https://dashboard.stripe.com/apikeys"
Start-Process "https://dashboard.stripe.com/webhooks"
Start-Process "https://dashboard.stripe.com/products"

Write-Host ""
Write-Host "[2] Confirm public business website is reachable..."

try {
    $Site = Invoke-WebRequest $PublicSite -UseBasicParsing -ErrorAction Stop
    Write-Host "$PublicSite returned HTTP $($Site.StatusCode)"
}
catch {
    throw "Public site is not reachable. Fix jaypventuresllc.com before going live. $($_.Exception.Message)"
}

Write-Host ""
Write-Host "[3] Collecting LIVE Stripe API values..."

$StripeSecret = Read-Required `
    -Prompt "Paste LIVE Stripe Secret Key (sk_live_...)" `
    -Pattern "^sk_live_[A-Za-z0-9_]+$" `
    -Example "sk_live_..."

$WebhookSecret = Read-Required `
    -Prompt "Paste LIVE Stripe Webhook Signing Secret (whsec_...)" `
    -Pattern "^whsec_[A-Za-z0-9_]+$" `
    -Example "whsec_..."

Write-Host ""
Write-Host "[4] Collecting LIVE Stripe Price IDs..."
Write-Host ""
Write-Host "Create/copy live Price API IDs for:"
Write-Host "- Member Access — $10/mo"
Write-Host "- Member Access — $100/yr"
Write-Host "- VIP Venture — $30/mo"
Write-Host "- VIP Venture — $300/yr"
Write-Host "- Creator Lane — $80/mo"
Write-Host "- Operator — $250/mo"
Write-Host "- Enterprise — $900/mo"
Write-Host ""

$MemberMonthly = Read-Required "LIVE price ID: Member Access `$10/mo" "^price_[A-Za-z0-9_]+$" "price_..."
$MemberAnnual = Read-Required "LIVE price ID: Member Access `$100/yr" "^price_[A-Za-z0-9_]+$" "price_..."
$VipMonthly = Read-Required "LIVE price ID: VIP Venture `$30/mo" "^price_[A-Za-z0-9_]+$" "price_..."
$VipAnnual = Read-Required "LIVE price ID: VIP Venture `$300/yr" "^price_[A-Za-z0-9_]+$" "price_..."
$CreatorMonthly = Read-Required "LIVE price ID: Creator Lane `$80/mo" "^price_[A-Za-z0-9_]+$" "price_..."
$OperatorMonthly = Read-Required "LIVE price ID: Operator `$250/mo" "^price_[A-Za-z0-9_]+$" "price_..."
$EnterpriseMonthly = Read-Required "LIVE price ID: Enterprise `$900/mo" "^price_[A-Za-z0-9_]+$" "price_..."

Write-Host ""
Write-Host "[5] Applying LIVE Stripe settings to Azure App Service..."

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $WebAppName `
    --settings `
        STRIPE_SECRET_KEY="$StripeSecret" `
        STRIPE_WEBHOOK_SECRET="$WebhookSecret" `
        PUBLIC_APP_BASE_URL="$BaseUrl" `
        STRIPE_AUTOMATIC_TAX_ENABLED="false" `
        STRIPE_PRICE_MEMBER_MONTHLY="$MemberMonthly" `
        STRIPE_PRICE_MEMBER_ANNUAL="$MemberAnnual" `
        STRIPE_PRICE_VIP_MONTHLY="$VipMonthly" `
        STRIPE_PRICE_VIP_ANNUAL="$VipAnnual" `
        STRIPE_PRICE_CREATOR_LANE_MONTHLY="$CreatorMonthly" `
        STRIPE_PRICE_OPERATOR_MONTHLY="$OperatorMonthly" `
        STRIPE_PRICE_ENTERPRISE_MONTHLY="$EnterpriseMonthly" `
        STRIPE_PRICE_ID_COMMUNITY="$MemberMonthly" `
        STRIPE_PRICE_ID_VIP="$VipMonthly" `
        STRIPE_PRICE_ENTERPRISE_ANNUAL="$EnterpriseMonthly" `
        STRIPE_PRICE_CUSTOM_IMPLEMENTATION="$OperatorMonthly" `
    --output none

Write-Host ""
Write-Host "[6] Restarting Azure Web App..."

az webapp restart `
    --resource-group $ResourceGroup `
    --name $WebAppName `
    --output none

Start-Sleep -Seconds 20

Write-Host ""
Write-Host "[7] Verifying app settings by name only..."

$Settings = az webapp config appsettings list `
    --resource-group $ResourceGroup `
    --name $WebAppName `
    -o json | ConvertFrom-Json

$Settings |
    Where-Object {
        $_.name -match "STRIPE_SECRET|STRIPE_WEBHOOK|STRIPE_PRICE|PUBLIC_APP_BASE_URL|STRIPE_AUTOMATIC_TAX"
    } |
    Select-Object name |
    Sort-Object name |
    Format-Table -AutoSize

Write-Host ""
Write-Host "[8] Verifying health..."

Invoke-WebRequest "$BaseUrl/api/health" -UseBasicParsing |
    Select-Object StatusCode,StatusDescription

Write-Host ""
Write-Host "[9] Checking checkout config status..."

try {
    Invoke-WebRequest "$BaseUrl/api/checkout/config-status" -UseBasicParsing |
        Select-Object StatusCode,StatusDescription,Content
}
catch {
    Write-Host "Checkout config status check failed:"
    Write-Host $_.Exception.Message
}

Write-Host ""
Write-Host "[10] Opening live pricing page..."

Start-Process "$BaseUrl/pricing?v=$(Get-Date -Format yyyyMMddHHmmss)"

Write-Host ""
Write-Host "======================================"
Write-Host "LIVE STRIPE CONFIGURATION COMPLETE"
Write-Host "======================================"
Write-Host ""
Write-Host "Next:"
Write-Host "1. Click a live pricing checkout button."
Write-Host "2. Confirm Stripe Checkout opens in LIVE mode."
Write-Host "3. Do NOT use test card 4242 in live mode."
Write-Host "4. Use a real low-risk payment method only if you are ready to process a real charge."
Write-Host ""
