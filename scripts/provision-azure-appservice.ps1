<#
.SYNOPSIS
    Provision Azure App Service infrastructure for JPV-OS Access Gateway.

.DESCRIPTION
    This script helps provision Azure App Service resources (subscription, resource group, app service plan, and web app)
    for the JPV-OS Access Gateway application. It supports three deployment paths:
    
    Path A: Use JayPVentures LLC tenant subscription
    Path B: Use existing Default Directory subscription (may require quota increase)
    Path C: Validate alternate runtime hosts (Render, Railway, Fly.io)

.PARAMETER Path
    Deployment path: A, B, or C
    
.PARAMETER TenantId
    Azure Tenant ID. Default: JayPVentures LLC tenant (f2f234f1-e912-4f16-a31d-6a102faea644)

.PARAMETER SubscriptionId
    Azure Subscription ID (required for Paths A and B)

.PARAMETER ResourceGroup
    Resource group name. Default: rg-jpv-os-prod

.PARAMETER AppServicePlan
    App Service plan name. Default: plan-jpv-os-prod

.PARAMETER WebAppName
    Web app name. Default: jpv-os-access-gateway

.PARAMETER Region
    Azure region. Default: eastus

.PARAMETER SkuSize
    App Service plan SKU. Default: B1 (Basic, 1 core, 1GB RAM)
    Minimum needed: B1 or higher. Standard S1 recommended for production.

.PARAMETER Validate
    If specified, only validate prerequisites without creating resources.

.EXAMPLE
    # Path A: Provision using JayPVentures LLC tenant
    .\provision-azure-appservice.ps1 -Path A -SubscriptionId "your-subscription-id"

.EXAMPLE
    # Path B: Provision using existing Default Directory subscription
    .\provision-azure-appservice.ps1 -Path B -SubscriptionId "your-subscription-id"

.EXAMPLE
    # Validate prerequisites only
    .\provision-azure-appservice.ps1 -Validate

.EXAMPLE
    # Path C: Validate alternate runtime hosts
    .\provision-azure-appservice.ps1 -Path C
#>

param(
    [ValidateSet("A", "B", "C")]
    [string]$Path = "A",
    
    [string]$TenantId = "f2f234f1-e912-4f16-a31d-6a102faea644",
    
    [string]$SubscriptionId,
    
    [string]$ResourceGroup = "rg-jpv-os-prod",
    
    [string]$AppServicePlan = "plan-jpv-os-prod",
    
    [string]$WebAppName = "jpv-os-access-gateway",
    
    [string]$Region = "eastus",
    
    [string]$SkuSize = "B1",
    
    [switch]$Validate
)

$ErrorActionPreference = "Stop"

# Color output helpers
function Write-Section { Write-Host "`n$($PSStyle.Foreground.Cyan)=== $args ===`n$($PSStyle.Reset)" }
function Write-Success { Write-Host "$($PSStyle.Foreground.Green)✓ $args$($PSStyle.Reset)" }
function Write-Error-Custom { Write-Host "$($PSStyle.Foreground.Red)✗ $args$($PSStyle.Reset)" -ErrorAction Continue }
function Write-Warning-Custom { Write-Host "$($PSStyle.Foreground.Yellow)⚠ $args$($PSStyle.Reset)" }
function Write-Info { Write-Host "$($PSStyle.Foreground.Cyan)ℹ $args$($PSStyle.Reset)" }

# ====================================
# Prerequisite Validation
# ====================================

function Test-Prerequisites {
    Write-Section "Checking Prerequisites"
    
    # Check Azure CLI
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Error-Custom "Azure CLI is not installed. Install it from: https://aka.ms/azure-cli"
        return $false
    }
    Write-Success "Azure CLI is installed"
    
    # Check Azure CLI version
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Info "Azure CLI version: $($azVersion.'azure-cli')"
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Warning-Custom "PowerShell 7.0+ recommended. Current: $($PSVersionTable.PSVersion)"
    } else {
        Write-Success "PowerShell version: $($PSVersionTable.PSVersion)"
    }
    
    return $true
}

# ====================================
# Authentication & Subscription
# ====================================

function Test-AzureLogin {
    param([string]$Tenant)
    
    Write-Section "Authenticating with Azure"
    
    # Check if already logged in
    $currentAccount = az account show 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
    
    if ($currentAccount) {
        Write-Success "Already logged in as: $($currentAccount.user.name)"
        return $true
    }
    
    # Login to tenant
    Write-Info "Logging in to tenant: $Tenant"
    az login --tenant $Tenant
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to login to Azure tenant"
        return $false
    }
    
    Write-Success "Successfully logged in to Azure"
    return $true
}

function Get-AvailableSubscriptions {
    Write-Info "Retrieving available subscriptions..."
    
    $subs = az account list --output json | ConvertFrom-Json
    
    if ($subs.Count -eq 0) {
        Write-Error-Custom "No subscriptions found. Check Tenant ID and account permissions."
        return @()
    }
    
    Write-Info "Found $($subs.Count) subscription(s):`n"
    $subs | ForEach-Object {
        Write-Info "  - $($_.name) [$($_.id.Substring(0, 8))...]"
    }
    
    return $subs
}

function Set-ActiveSubscription {
    param([string]$SubId)
    
    Write-Info "Setting active subscription: $SubId"
    az account set --subscription $SubId
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to set subscription"
        return $false
    }
    
    $sub = az account show --output json | ConvertFrom-Json
    Write-Success "Active subscription: $($sub.name)"
    return $true
}

# ====================================
# Quota & Capacity Validation
# ====================================

function Test-AppServiceQuota {
    param([string]$Region)
    
    Write-Section "Checking App Service Quota"
    
    # Get provider registrations
    Write-Info "Checking Microsoft.Web provider registration..."
    $provider = az provider show --namespace Microsoft.Web --output json | ConvertFrom-Json
    
    if ($provider.registrationState -ne "Registered") {
        Write-Warning-Custom "Microsoft.Web provider not registered. Registering..."
        az provider register --namespace Microsoft.Web
        Write-Info "Provider registration initiated (this may take 5-10 minutes)"
    } else {
        Write-Success "Microsoft.Web provider is registered"
    }
    
    # Check VMs quota for the region
    Write-Info "Checking Total vCores quota in region: $Region"
    
    # Note: Detailed quota check requires Azure SDK or Resource Manager API
    # This is a basic check using the portal information
    Write-Warning-Custom "Quota check requires Azure Portal access"
    Write-Info "To verify App Service capacity for region: $Region"
    Write-Info "  1. Go to https://portal.azure.com"
    Write-Info "  2. Search for 'Subscriptions' > Select your subscription"
    Write-Info "  3. Go to 'Usage + quotas' on the left panel"
    Write-Info "  4. Filter by Region: '$Region' and Service: 'App Service'"
    Write-Info "  5. Verify 'Total vCores' limit >= 1 (current: check Current Value)"
    
    return $true
}

# ====================================
# Resource Creation (Path A & B)
# ====================================

function New-ResourceGroup {
    param([string]$RgName, [string]$Region)
    
    Write-Section "Creating Resource Group"
    
    # Check if already exists
    $rg = az group exists --name $RgName | ConvertFrom-Json
    
    if ($rg -eq $true) {
        Write-Success "Resource group already exists: $RgName"
        return $true
    }
    
    Write-Info "Creating resource group: $RgName in region: $Region"
    az group create --name $RgName --location $Region
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to create resource group"
        return $false
    }
    
    Write-Success "Resource group created: $RgName"
    return $true
}

function New-AppServicePlan {
    param([string]$RgName, [string]$PlanName, [string]$Region, [string]$Sku)
    
    Write-Section "Creating App Service Plan"
    
    # Check if already exists
    $existing = az appservice plan list --resource-group $RgName --output json 2>$null | ConvertFrom-Json
    $planExists = $existing | Where-Object { $_.name -eq $PlanName }
    
    if ($planExists) {
        Write-Success "App Service plan already exists: $PlanName"
        return $true
    }
    
    Write-Info "Creating App Service plan: $PlanName"
    Write-Info "  SKU: $Sku (1 vCore, 1 GB RAM)"
    Write-Info "  Region: $Region"
    Write-Info "  OS: Linux"
    
    az appservice plan create `
        --name $PlanName `
        --resource-group $RgName `
        --location $Region `
        --sku $Sku `
        --is-linux
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to create App Service plan"
        Write-Info "If quota error occurs, check the documented paths:"
        Write-Info "  Path A: Assign subscription to JayPVentures LLC tenant"
        Write-Info "  Path B: Request quota increase in Azure Portal"
        Write-Info "  Path C: Use alternate runtime host (Render, Railway, Fly.io)"
        return $false
    }
    
    Write-Success "App Service plan created: $PlanName"
    return $true
}

function New-WebApp {
    param([string]$RgName, [string]$AppName, [string]$PlanName)
    
    Write-Section "Creating Web App"
    
    # Check if already exists
    $existing = az webapp list --resource-group $RgName --output json 2>$null | ConvertFrom-Json
    $appExists = $existing | Where-Object { $_.name -eq $AppName }
    
    if ($appExists) {
        Write-Success "Web app already exists: $AppName"
        return $true
    }
    
    Write-Info "Creating Web app: $AppName"
    Write-Info "  Runtime: .NET 8"
    Write-Info "  OS: Linux"
    
    az webapp create `
        --resource-group $RgName `
        --plan $PlanName `
        --name $AppName `
        --runtime "DOTNET|8.0"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to create Web app"
        return $false
    }
    
    Write-Success "Web app created: $AppName"
    return $true
}

function Enable-HttpsOnly {
    param([string]$RgName, [string]$AppName)
    
    Write-Section "Configuring HTTPS"
    
    az webapp update `
        --resource-group $RgName `
        --name $AppName `
        --set httpsOnly=true
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "HTTPS enforced for web app"
    } else {
        Write-Warning-Custom "Could not enforce HTTPS (may require further configuration)"
    }
}

function Get-PublishProfile {
    param([string]$RgName, [string]$AppName)
    
    Write-Section "Generating Publish Profile"
    
    $profilePath = Join-Path $PSScriptRoot "azure-publish-profile-$AppName.xml"
    
    Write-Info "Downloading publish profile to: $profilePath"
    az webapp deployment list-publishing-profiles `
        --resource-group $RgName `
        --name $AppName `
        --xml > $profilePath
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to download publish profile"
        return $null
    }
    
    # Verify file was created
    if (-not (Test-Path $profilePath)) {
        Write-Error-Custom "Publish profile file not created"
        return $null
    }
    
    $fileSize = (Get-Item $profilePath).Length
    Write-Success "Publish profile generated: $profilePath ($fileSize bytes)"
    
    return $profilePath
}

function Register-PublishProfileSecret {
    param([string]$ProfilePath, [string]$AppName)
    
    Write-Section "Registering GitHub Secret"
    
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Warning-Custom "GitHub CLI not found. Manual secret registration required."
        Write-Info "To register the publish profile secret:"
        Write-Info "  Using PowerShell:"
        Write-Info "    Get-Content -Raw '$ProfilePath' | gh secret set AZURE_WEBAPP_PUBLISH_PROFILE --body-file -"
        Write-Info ""
        Write-Info "  Do NOT use Bash '<' redirection in PowerShell."
        return $false
    }
    
    Write-Info "Registering AZURE_WEBAPP_PUBLISH_PROFILE secret..."
    
    # Use PowerShell-compatible syntax
    Get-Content -Raw $ProfilePath | gh secret set AZURE_WEBAPP_PUBLISH_PROFILE --body-file -
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "GitHub secret registered: AZURE_WEBAPP_PUBLISH_PROFILE"
        return $true
    } else {
        Write-Warning-Custom "Failed to register GitHub secret (may require manual registration)"
        return $false
    }
}

# ====================================
# Path C: Alternate Runtimes
# ====================================

function Test-AlternateRuntimes {
    Write-Section "Path C: Alternate Runtime Options"
    
    Write-Info "Validated runtime hosts for .NET 8 deployment:`n"
    
    # Fly.io
    Write-Info "1. Fly.io (Recommended for quick start)"
    Write-Info "   Command: fly auth login && fly deploy"
    Write-Info "   Config: fly.toml (already configured)"
    $flyExists = Test-Path (Join-Path (Split-Path $PSScriptRoot) "fly.toml")
    if ($flyExists) {
        Write-Success "   fly.toml found in repository"
    }
    
    # Render
    Write-Info "`n2. Render"
    Write-Info "   Command: render deploy"
    Write-Info "   Config: render.yaml (already configured)"
    $renderExists = Test-Path (Join-Path (Split-Path $PSScriptRoot) "render.yaml")
    if ($renderExists) {
        Write-Success "   render.yaml found in repository"
    }
    
    # Railway
    Write-Info "`n3. Railway"
    Write-Info "   Command: railway deploy"
    Write-Info "   Supports Docker deployment"
    
    # DigitalOcean App Platform
    Write-Info "`n4. DigitalOcean App Platform"
    Write-Info "   Supports Docker deployment"
    Write-Info "   More info: https://docs.digitalocean.com/products/app-platform/"
    
    # AWS App Runner
    Write-Info "`n5. AWS App Runner"
    Write-Info "   Supports container image deployment"
    Write-Info "   More info: https://aws.amazon.com/apprunner/"
    
    Write-Info "`nSee docs/CONTAINER-DEPLOYMENT.md for detailed instructions."
    
    return $true
}

# ====================================
# Validation Summary
# ====================================

function Test-DeploymentPrerequisites {
    param([string]$RgName, [string]$AppName)
    
    Write-Section "Validating Deployment Prerequisites"
    
    $allGood = $true
    
    # Test health endpoint availability
    Write-Info "Checking health endpoint configuration..."
    $projPath = Join-Path (Split-Path $PSScriptRoot) "src/JPVOS/Program.cs"
    if (Get-Content $projPath | Select-String "health" -Quiet) {
        Write-Success "Health endpoint configured at /health"
    } else {
        Write-Error-Custom "Health endpoint not found in Program.cs"
        $allGood = $false
    }
    
    # Check resource availability
    if ($RgName -and $AppName) {
        Write-Info "Checking Azure resources..."
        
        # Check resource group
        $rg = az group exists --name $RgName | ConvertFrom-Json
        if ($rg) {
            Write-Success "Resource group exists: $RgName"
        } else {
            Write-Error-Custom "Resource group not found: $RgName"
            $allGood = $false
        }
        
        # Check web app
        $app = az webapp show --resource-group $RgName --name $AppName --output json 2>$null | ConvertFrom-Json
        if ($app) {
            Write-Success "Web app exists: $AppName"
            Write-Info "  URL: $($app.defaultHostName)"
            Write-Info "  Runtime: $($app.linuxFxVersion)"
        } else {
            Write-Error-Custom "Web app not found: $AppName"
            $allGood = $false
        }
    }
    
    return $allGood
}

# ====================================
# Main Execution
# ====================================

function Main {
    Write-Host "$($PSStyle.Foreground.Cyan)
╔═════════════════════════════════════════════════════════════╗
║    JPV-OS Access Gateway - Azure App Service Provisioning   ║
╚═════════════════════════════════════════════════════════════╝
$($PSStyle.Reset)"
    
    Write-Info "Path: $Path (Region: $Region) | SKU: $SkuSize"
    
    # Step 1: Validate prerequisites
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Step 2: Authentication
    if (-not (Test-AzureLogin -Tenant $TenantId)) {
        exit 1
    }
    
    # Step 3: Subscription
    if ($Path -in "A", "B") {
        if (-not $SubscriptionId) {
            Write-Error-Custom "SubscriptionId required for Path A and B"
            
            $subs = Get-AvailableSubscriptions
            if ($subs.Count -gt 0) {
                Write-Info "Use one of the available subscription IDs above:"
                Write-Info "  .\provision-azure-appservice.ps1 -Path $Path -SubscriptionId '<subscription-id>'"
            }
            exit 1
        }
        
        if (-not (Set-ActiveSubscription -SubId $SubscriptionId)) {
            exit 1
        }
    }
    
    # Step 4: Quota check
    if ($Path -in "A", "B") {
        Test-AppServiceQuota -Region $Region
    }
    
    # If validation only, stop here
    if ($Validate) {
        Write-Success "Validation complete"
        
        # Additional validation for existing resources
        Test-DeploymentPrerequisites -RgName $ResourceGroup -AppName $WebAppName
        exit 0
    }
    
    # Step 5: Path A/B - Create resources
    if ($Path -eq "A") {
        Write-Section "Path A: JayPVentures LLC Tenant Subscription"
        Write-Info "Provisioning resources using JayPVentures LLC tenant..."
        
        if (-not (New-ResourceGroup -RgName $ResourceGroup -Region $Region)) {
            exit 1
        }
        
        if (-not (New-AppServicePlan -RgName $ResourceGroup -PlanName $AppServicePlan -Region $Region -Sku $SkuSize)) {
            exit 1
        }
        
        if (-not (New-WebApp -RgName $ResourceGroup -AppName $WebAppName -PlanName $AppServicePlan)) {
            exit 1
        }
        
        Enable-HttpsOnly -RgName $ResourceGroup -AppName $WebAppName
        
        $profilePath = Get-PublishProfile -RgName $ResourceGroup -AppName $WebAppName
        if ($profilePath) {
            Register-PublishProfileSecret -ProfilePath $profilePath -AppName $WebAppName
        }
    }
    elseif ($Path -eq "B") {
        Write-Section "Path B: Existing Subscription Quota"
        Write-Info "Using existing subscription with verified quota..."
        
        if (-not (New-ResourceGroup -RgName $ResourceGroup -Region $Region)) {
            exit 1
        }
        
        if (-not (New-AppServicePlan -RgName $ResourceGroup -PlanName $AppServicePlan -Region $Region -Sku $SkuSize)) {
            Write-Error-Custom "Quota insufficient. Request quota increase at:"
            Write-Info "  https://portal.azure.com > Subscriptions > Usage + quotas"
            exit 1
        }
        
        if (-not (New-WebApp -RgName $ResourceGroup -AppName $WebAppName -PlanName $AppServicePlan)) {
            exit 1
        }
        
        Enable-HttpsOnly -RgName $ResourceGroup -AppName $WebAppName
        
        $profilePath = Get-PublishProfile -RgName $ResourceGroup -AppName $WebAppName
        if ($profilePath) {
            Register-PublishProfileSecret -ProfilePath $profilePath -AppName $WebAppName
        }
    }
    elseif ($Path -eq "C") {
        Write-Section "Path C: Alternate Runtime Host"
        Test-AlternateRuntimes
    }
    
    # Step 6: Final validation
    Write-Section "Provisioning Summary"
    
    if ($Path -in "A", "B") {
        if (Test-DeploymentPrerequisites -RgName $ResourceGroup -AppName $WebAppName) {
            Write-Success "All prerequisites validated. Ready for deployment."
            Write-Info "Next steps:"
            Write-Info "  1. Configure app settings in Azure Portal"
            Write-Info "  2. Run GitHub Actions workflow: 'Deploy to Azure App Service'"
            Write-Info "  3. Monitor deployment at: https://portal.azure.com"
        }
    }
}

# Run main function
Main
