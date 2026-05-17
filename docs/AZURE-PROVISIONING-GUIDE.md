# Azure App Service Provisioning Guide

## Overview

This guide helps you provision Azure App Service infrastructure for the JPV-OS Access Gateway application. Azure infrastructure provisioning is critical for deploying the real production instance of the app.

## Prerequisites

### Required Tools

1. **Azure CLI** - Command-line interface for Azure management
   - Download: https://aka.ms/azure-cli
   - Verify: `az --version`

2. **PowerShell 7.0+** (for Windows provisioning script)
   - Download: https://github.com/PowerShell/PowerShell/releases
   - Verify: `pwsh --version`

3. **GitHub CLI** (optional, for automated secret registration)
   - Download: https://cli.github.com
   - Verify: `gh --version`

### Azure Subscription

You must have an Azure subscription with usable App Service quota. Three paths are available:

- **Path A**: JayPVentures LLC tenant subscription
- **Path B**: Existing Default Directory subscription (may require quota increase)
- **Path C**: Alternate runtime host (Render, Railway, Fly.io, etc.)

## Quick Start

### Windows (PowerShell)

```powershell
# Validate prerequisites only
.\scripts\provision-azure-appservice.ps1 -Validate

# Provision with Path A (JayPVentures LLC tenant)
.\scripts\provision-azure-appservice.ps1 -Path A -SubscriptionId "YOUR-SUBSCRIPTION-ID"

# Provision with Path B (existing subscription, after quota increase)
.\scripts\provision-azure-appservice.ps1 -Path B -SubscriptionId "YOUR-SUBSCRIPTION-ID"

# List alternate runtime options (Path C)
.\scripts\provision-azure-appservice.ps1 -Path C
```

### Linux / macOS (Bash)

```bash
# Validate prerequisites only
./scripts/provision-azure-appservice.sh -Validate

# Provision with Path A (JayPVentures LLC tenant)
./scripts/provision-azure-appservice.sh -Path A -SubscriptionId "YOUR-SUBSCRIPTION-ID"

# Provision with Path B (existing subscription, after quota increase)
./scripts/provision-azure-appservice.sh -Path B -SubscriptionId "YOUR-SUBSCRIPTION-ID"

# List alternate runtime options (Path C)
./scripts/provision-azure-appservice.sh -Path C
```

## Deployment Paths

### Path A: JayPVentures LLC Tenant Subscription

**Recommended when:** You have access to a subscription under the JayPVentures LLC tenant.

**Steps:**

1. Obtain a JayPVentures LLC tenant subscription ID
2. Run the provisioning script:
   ```powershell
   .\scripts\provision-azure-appservice.ps1 -Path A -SubscriptionId "sub-xxx"
   ```
3. The script will:
   - Authenticate with Azure
   - Create resource group
   - Create App Service plan (B1 SKU recommended)
   - Create Web App with .NET 8 runtime
   - Generate publish profile
   - Register GitHub secrets automatically (if GitHub CLI available)

4. Verify prerequisites are met:
   ```
   ✓ Azure subscription with usable App Service quota is active
   ✓ `az appservice plan create` succeeded
   ✓ `az webapp create` succeeded
   ✓ Real publish profile generated
   ```

5. Configure app settings in [Azure Portal](https://portal.azure.com):
   - Set `STRIPE_SECRET_KEY` and webhook secret
   - Set `DISCORD_CLIENT_ID`, `DISCORD_CLIENT_SECRET`, etc.
   - Configure other required environment variables

6. Deploy using GitHub Actions workflow:
   - Go to Repository > Actions
   - Select "Deploy to Azure App Service"
   - Click "Run workflow"

### Path B: Existing Subscription Quota Increase

**Recommended when:** You have an existing Azure subscription but quota is insufficient.

**Common Issue:** "Total VMs quota is 0" or similar quota limit error

**Steps:**

1. Request quota increase in Azure Portal:
   - Go to https://portal.azure.com
   - Search for "Subscriptions" > Select your subscription
   - Select "Usage + quotas" on the left panel
   - Filter by Region: Select your region (e.g., "East US")
   - Find "Total vCores" or similar capacity metric
   - Click "Request quota increase"
   - Request minimum: 1 vCore
   - Recommended: 2-4 vCores for production

2. Wait for quota increase approval (typically 1-24 hours)

3. Run the provisioning script:
   ```powershell
   .\scripts\provision-azure-appservice.ps1 -Path B -SubscriptionId "your-sub-id"
   ```

4. Follow the same deployment steps as Path A

### Path C: Alternate Runtime Hosts

**Recommended when:** Azure provisioning cannot be completed in your timeframe.

**Supported Platforms:**

#### 1. Fly.io (Recommended for quick start)

```bash
fly auth login
fly deploy  # Uses existing fly.toml
```

- Zero-downtime deployments
- Global Anycast network
- Health checks configured at `/health`
- Configuration: `fly.toml` (already configured)

#### 2. Render

```bash
render deploy  # Uses existing render.yaml
```

- Free and paid tiers available
- Automatic HTTPS
- Configuration: `render.yaml` (already configured)

#### 3. Railway

```bash
railway deploy
```

- Container-based deployment
- Easy environment variable management

#### 4. DigitalOcean App Platform

- Container support
- Integrated monitoring
- Documentation: https://docs.digitalocean.com/products/app-platform/

#### 5. AWS App Runner

- Container orchestration
- Auto-scaling
- Documentation: https://aws.amazon.com/apprunner/

For detailed instructions on alternate platforms, see [CONTAINER-DEPLOYMENT.md](./CONTAINER-DEPLOYMENT.md).

## Advanced Configuration

### Custom Parameters

The provisioning scripts accept optional parameters:

```powershell
# PowerShell example with all options
.\scripts\provision-azure-appservice.ps1 `
    -Path A `
    -SubscriptionId "your-id" `
    -TenantId "f2f234f1-e912-4f16-a31d-6a102faea644" `
    -ResourceGroup "custom-rg" `
    -AppServicePlan "custom-plan" `
    -WebAppName "custom-app-name" `
    -Region "westus2" `
    -SkuSize "S1"  # B1 (1 core), S1 (1 core), S2 (2 cores), etc.
```

### App Service Plan SKU Options

| SKU | Cores | RAM | Price | Best For |
|-----|-------|-----|-------|----------|
| B1  | 1     | 1GB | $10/mo | Development, small production |
| B2  | 2     | 3.5GB | $50/mo | Small production workloads |
| B3  | 4     | 7GB | $100/mo | Medium production |
| S1  | 1     | 1.75GB | $75/mo | Production (1 instance) |
| S2  | 2     | 3.5GB | $150/mo | Production (2 instances) |
| S3  | 4     | 7GB | $300/mo | Production (3 instances) |
| P1V2 | 1 | 3.5GB | $195/mo | High-performance |

Recommendation: **B1 for quick validation, S1+ for production**

### Troubleshooting

#### Authentication Failures

```powershell
# Sign out and re-authenticate
az logout
.\scripts\provision-azure-appservice.ps1 -Path A -SubscriptionId "your-id"
```

#### Quota Errors

```
Error: Total VMs quota is 0
```

**Solution:** Request quota increase (Path B) or use alternate runtime (Path C)

#### Resource Already Exists

The script checks for existing resources and reuses them. If you want to recreate:

```powershell
# Delete via Azure Portal or CLI
az group delete --name "rg-jpv-os-prod"

# Re-run provisioning script
.\scripts\provision-azure-appservice.ps1 -Path A -SubscriptionId "your-id"
```

#### Publish Profile Secret Not Registered

If GitHub CLI is not available, manually register the secret:

```powershell
# PowerShell (recommended)
Get-Content -Raw ".\scripts\azure-publish-profile-jpv-os-access-gateway.xml" | `
    gh secret set AZURE_WEBAPP_PUBLISH_PROFILE --body-file -
```

```bash
# Bash
cat ./scripts/azure-publish-profile-jpv-os-access-gateway.xml | \
    gh secret set AZURE_WEBAPP_PUBLISH_PROFILE --body-file -
```

## Deployment Workflow

After provisioning, the complete deployment workflow is:

```
1. Provisioning (this script)
   ├─ Azure subscription verified
   ├─ Resource group created
   ├─ App Service plan created
   ├─ Web app created (.NET 8)
   ├─ HTTPS configured
   └─ Publish profile registered

2. Pre-Deployment (manual)
   ├─ App settings configured (Stripe, Discord, etc.)
   ├─ Custom domain configured (optional)
   └─ Monitoring configured (optional)

3. GitHub Actions Deployment
   ├─ Code pushed to main
   ├─ CI workflow builds and tests
   ├─ Deploy workflow publishes to Azure
   └─ Application runs at https://jpv-os-access-gateway.azurewebsites.net
```

## Production Checklist

Before deploying to production:

- [ ] Azure subscription provisioned successfully
- [ ] `az appservice plan create` succeeded
- [ ] `az webapp create` succeeded
- [ ] Publish profile downloaded and registered
- [ ] Environment variables configured (Stripe, Discord, etc.)
- [ ] HTTPS enforced (automatic with provisioning script)
- [ ] Health check endpoint accessible (`GET /health`)
- [ ] Database backup strategy in place
- [ ] Monitoring/logging configured
- [ ] Incident response plan documented

## Support & References

- **Azure Documentation**: https://docs.microsoft.com/en-us/azure/app-service/
- **Azure CLI Reference**: https://docs.microsoft.com/en-us/cli/azure/
- **App Service Limits**: https://docs.microsoft.com/en-us/azure/app-service/limits-quotas-constraints
- **Pricing**: https://azure.microsoft.com/en-us/pricing/details/app-service/

## Related Documentation

- [Azure App Service Deployment Plan](./AZURE-APP-SERVICE-DEPLOYMENT.md) - Infrastructure requirements
- [Container Deployment Guide](./CONTAINER-DEPLOYMENT.md) - Alternate platforms
- [Deployment Guide](./DEPLOYMENT.md) - General deployment information
- [Local Setup](./LOCAL-SETUP.md) - Development environment setup
