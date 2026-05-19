param(
    [ValidateSet("test","live")]
    [string]$Mode = "test",

    [switch]$NonInteractive,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path ".").Path
$GeneratedDir = Join-Path $RepoRoot "infrastructure\stripe\generated"
New-Item -ItemType Directory -Force -Path $GeneratedDir | Out-Null

$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$JsonPath = Join-Path $GeneratedDir "stripe-pricing.$Mode.json"
$ReportPath = Join-Path $GeneratedDir "stripe-pricing.$Mode.$Stamp.md"
$EnvTemplatePath = Join-Path $GeneratedDir "stripe-env.$Mode.template"

$StripeCmd = Join-Path $RepoRoot "stripe.exe"
if (!(Test-Path $StripeCmd)) {
    throw "Local stripe.exe not found at $StripeCmd"
}

function Invoke-StripeJson {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$CommandArgs
    )

    $raw = & $StripeCmd @CommandArgs 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($raw -join "`n").Trim()

    if ($exitCode -ne 0) {
        throw "Stripe CLI failed with exit code $exitCode`: $text"
    }

    if (-not ($text.StartsWith("{") -or $text.StartsWith("["))) {
        throw "Stripe CLI did not return JSON: $text"
    }

    return $text | ConvertFrom-Json
}

$Tiers = @(
    @{ key="member_access_monthly"; name="Member Access"; amount=900; interval="month" },
    @{ key="member_access_annual"; name="Member Access Annual"; amount=9000; interval="year" },
    @{ key="vip_venture_monthly"; name="VIP Venture"; amount=2900; interval="month" },
    @{ key="vip_venture_annual"; name="VIP Venture Annual"; amount=29000; interval="year" },
    @{ key="creator_lane_monthly"; name="Creator Lane"; amount=7900; interval="month" },
    @{ key="operator_monthly"; name="Operator"; amount=24900; interval="month" },
    @{ key="enterprise_monthly"; name="Enterprise"; amount=89900; interval="month" }
)

$Results = [ordered]@{}

"# Stripe Pricing Report`nMode: $Mode`nGenerated: $(Get-Date)`nStripe CLI: $StripeCmd`n" |
    Set-Content $ReportPath -Encoding UTF8

foreach ($tier in $Tiers) {
    $lookup = $tier.key
    "`n## $lookup" | Add-Content $ReportPath

    $existing = Invoke-StripeJson -CommandArgs @(
        "get",
        "/v1/prices",
        "-d",
        "lookup_keys[]=$lookup",
        "-d",
        "limit=1"
    )

    if ($existing.data.Count -gt 0) {
        $price = $existing.data[0]
        $productId = $price.product
        "Reused price: $($price.id)" | Add-Content $ReportPath
    } else {
        $product = Invoke-StripeJson -CommandArgs @(
            "post",
            "/v1/products",
            "-d",
            "name=$($tier.name)",
            "-d",
            "description=JPV-OS Access Gateway tier: $($tier.name)",
            "-d",
            "metadata[ecosystem]=JPV-OS",
            "-d",
            "metadata[legal_entity]=JayPVentures LLC",
            "-d",
            "metadata[mode]=$Mode"
        )

        $price = Invoke-StripeJson -CommandArgs @(
            "post",
            "/v1/prices",
            "-d",
            "product=$($product.id)",
            "-d",
            "currency=usd",
            "-d",
            "unit_amount=$($tier.amount)",
            "-d",
            "recurring[interval]=$($tier.interval)",
            "-d",
            "lookup_key=$lookup",
            "-d",
            "tax_behavior=exclusive",
            "-d",
            "metadata[ecosystem]=JPV-OS",
            "-d",
            "metadata[legal_entity]=JayPVentures LLC",
            "-d",
            "metadata[mode]=$Mode"
        )

        $productId = $product.id
        "Created product: $productId" | Add-Content $ReportPath
        "Created price: $($price.id)" | Add-Content $ReportPath
    }

    $Results[$lookup] = [ordered]@{
        name = $tier.name
        amount = $tier.amount
        currency = "usd"
        interval = $tier.interval
        product_id = $productId
        price_id = $price.id
        lookup_key = $lookup
    }
}

$Output = [ordered]@{
    mode = $Mode
    generated = (Get-Date).ToString("o")
    stripe_cli = $StripeCmd
    prices = $Results
}

$Output | ConvertTo-Json -Depth 10 | Set-Content $JsonPath -Encoding UTF8

$envLines = @(
    "# Stripe $Mode environment template",
    "# Generated $(Get-Date)",
    "STRIPE_MODE=$Mode"
)

foreach ($k in $Results.Keys) {
    $envName = "STRIPE_PRICE_" + $k.ToUpper()
    $envLines += "$envName=$($Results[$k].price_id)"
}

$envLines | Set-Content $EnvTemplatePath -Encoding UTF8

Write-Host "======================================"
Write-Host "STRIPE CONFIG COMPLETE"
Write-Host "Mode: $Mode"
Write-Host "JSON: $JsonPath"
Write-Host "Report: $ReportPath"
Write-Host "Env template: $EnvTemplatePath"
Write-Host "======================================"
exit 0
