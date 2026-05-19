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
        $Secure = Read-Host $Prompt -AsSecureString
        $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
        $Value = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        if ($Value -notmatch $Pattern) {
            Write-Host "Invalid. Expected format: $Example"
        }
    } until ($Value -match $Pattern)

    return $Value.Trim()
}

function Read-Price {
    param([string]$Label)

    do {
        $Value = Read-Host "Paste LIVE Stripe Price ID for $Label"

        if ($Value -notmatch "^price_[A-Za-z0-9_]+$") {
            Write-Host "Invalid. Must be a real live Stripe Price API ID beginning with price_"
        }
    } until ($Value -match "^price_[A-Za-z0-9_]+$")

    return $Value.Trim()
}

Write-Host ""
Write-Host "======================================"
Write-Host "JPV LIVE STRIPE FULL SETUP"
Write-Host "======================================"
Write-Host ""
Write-Host "This configures LIVE Stripe values in Azure App Service."
Write-Host "No Stripe CLI required."
Write-Host "Secrets are entered securely and not printed."
Write-Host ""

$Confirm = Read-Host "Type LIVE to continue"
if ($Confirm -ne "LIVE") {
    throw "Cancelled."
}

Write-Host ""
Write-Host "[1] Opening required Stripe pages..."
Start-Process "https://dashboard.stripe.com/apikeys"
Start-Process "https://dashboard.stripe.com/webhooks"
Start-Process "https://dashboard.stripe.com/products"

Write-Host ""
Write-Host "[2] Verifying public business website..."
$Site = Invoke-WebRequest $PublicSite -UseBasicParsing -ErrorAction Stop
Write-Host "$PublicSite returned HTTP $($Site.StatusCode)"

Write-Host ""
Write-Host "[3] Required manual Stripe items:"
Write-Host "- LIVE secret key: Developers > API keys > sk_live_..."
Write-Host "- LIVE webhook endpoint: $BaseUrl/api/stripe/webhook"
Write-Host "- LIVE webhook signing secret: whsec_..."
Write-Host "- LIVE product Price API IDs: price_..."
Write-Host ""

Write-Host "Webhook events to enable:"
Write-Host "checkout.session.completed"
Write-Host "invoice.payment_succeeded"
Write-Host "invoice.payment_failed"
Write-Host "customer.subscription.created"
Write-Host "customer.subscription.updated"
Write-Host "customer.subscription.deleted"

Write-Host ""
Write-Host "[4] Paste LIVE values."

$StripeSecret = Read-Required "Paste LIVE Stripe secret key sk_live_..." "^sk_live_[A-Za-z0-9_]+$" "sk_live_..."
$WebhookSecret = Read-Required "Paste LIVE Stripe webhook signing secret whsec_..." "^whsec_[A-Za-z0-9_]+$" "whsec_..."

$MemberMonthly = Read-Price "Member Access - $10/mo"
$MemberAnnual = Read-Price "Member Access - $100/yr"
$VipMonthly = Read-Price "VIP Venture - $30/mo"
$VipAnnual = Read-Price "VIP Venture - $300/yr"
$CreatorMonthly = Read-Price "Creator Lane - $80/mo"
$OperatorMonthly = Read-Price "Operator - $250/mo"
$EnterpriseMonthly = Read-Price "Enterprise - $900/mo"

Write-Host ""
Write-Host "[5] Applying live settings to Azure. Values will not be printed."

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

Remove-Variable StripeSecret -Force -ErrorAction SilentlyContinue
Remove-Variable WebhookSecret -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[6] Restarting Azure Web App..."

az webapp restart `
  --resource-group $ResourceGroup `
  --name $WebAppName `
  --output none

Start-Sleep -Seconds 20

Write-Host ""
Write-Host "[7] Verifying Azure setting names only..."

$Settings = az webapp config appsettings list `
  --resource-group $ResourceGroup `
  --name $WebAppName `
  -o json | ConvertFrom-Json

$Settings |
  Where-Object { $_.name -match "STRIPE_SECRET|STRIPE_WEBHOOK|STRIPE_PRICE|PUBLIC_APP_BASE_URL|STRIPE_AUTOMATIC_TAX" } |
  Select-Object name |
  Sort-Object name |
  Format-Table -AutoSize

Write-Host ""
Write-Host "[8] Checking app health..."

Invoke-WebRequest "$BaseUrl/api/health" -UseBasicParsing |
  Select-Object StatusCode,StatusDescription

Write-Host ""
Write-Host "[9] Opening live pricing page..."

Start-Process "$BaseUrl/pricing?v=$(Get-Date -Format yyyyMMddHHmmss)"

Write-Host ""
Write-Host "======================================"
Write-Host "LIVE STRIPE SETUP COMPLETE"
Write-Host "======================================"
Write-Host "Do not use test card 4242 in live mode."
Write-Host "Only run a real payment when ready for a real charge."
