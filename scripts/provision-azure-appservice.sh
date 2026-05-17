#!/usr/bin/env bash

set -euo pipefail

# Establish script and repository root directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

write_section() {
    echo -e "\n${CYAN}=== $@ ===${NC}\n"
}

write_success() {
    echo -e "${GREEN}✓ $@${NC}"
}

write_error() {
    echo -e "${RED}✗ $@${NC}"
}

write_warning() {
    echo -e "${YELLOW}⚠ $@${NC}"
}

write_info() {
    echo -e "${CYAN}ℹ $@${NC}"
}

# Parse arguments
PATH_OPTION="A"
TENANT_ID="f2f234f1-e912-4f16-a31d-6a102faea644"
SUBSCRIPTION_ID=""
RESOURCE_GROUP="rg-jpv-os-prod"
APP_SERVICE_PLAN="plan-jpv-os-prod"
WEB_APP_NAME="jpv-os-access-gateway"
REGION="eastus"
SKU_SIZE="B1"
VALIDATE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -Path) PATH_OPTION="$2"; shift 2 ;;
        -TenantId) TENANT_ID="$2"; shift 2 ;;
        -SubscriptionId) SUBSCRIPTION_ID="$2"; shift 2 ;;
        -ResourceGroup) RESOURCE_GROUP="$2"; shift 2 ;;
        -AppServicePlan) APP_SERVICE_PLAN="$2"; shift 2 ;;
        -WebAppName) WEB_APP_NAME="$2"; shift 2 ;;
        -Region) REGION="$2"; shift 2 ;;
        -SkuSize) SKU_SIZE="$2"; shift 2 ;;
        -Validate) VALIDATE_ONLY=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ====================================
# Prerequisite Validation
# ====================================

test_prerequisites() {
    write_section "Checking Prerequisites"
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        write_error "Azure CLI is not installed. Install it from: https://aka.ms/azure-cli"
        return 1
    fi
    write_success "Azure CLI is installed"
    
    # Check Azure CLI version
    AZ_VERSION=$(az version --output json | jq -r '."azure-cli"')
    write_info "Azure CLI version: $AZ_VERSION"
    
    # Check Bash version
    write_info "Bash version: $BASH_VERSION"
    
    return 0
}

# ====================================
# Authentication & Subscription
# ====================================

test_azure_login() {
    local TENANT=$1
    
    write_section "Authenticating with Azure"
    
    # Check if already logged in
    if az account show &>/dev/null; then
        CURRENT_ACCOUNT=$(az account show --output json | jq -r '.user.name')
        write_success "Already logged in as: $CURRENT_ACCOUNT"
        return 0
    fi
    
    # Login to tenant
    write_info "Logging in to tenant: $TENANT"
    az login --tenant "$TENANT"
    
    if [ $? -ne 0 ]; then
        write_error "Failed to login to Azure tenant"
        return 1
    fi
    
    write_success "Successfully logged in to Azure"
    return 0
}

get_available_subscriptions() {
    write_info "Retrieving available subscriptions..."
    
    SUBS=$(az account list --output json)
    COUNT=$(echo "$SUBS" | jq 'length')
    
    if [ "$COUNT" -eq 0 ]; then
        write_error "No subscriptions found. Check Tenant ID and account permissions."
        return 1
    fi
    
    write_info "Found $COUNT subscription(s):\n"
    echo "$SUBS" | jq -r '.[] | "  - \(.name) [\(.id | .[0:8])...]"'
    
    return 0
}

set_active_subscription() {
    local SUB_ID=$1
    
    write_info "Setting active subscription: $SUB_ID"
    az account set --subscription "$SUB_ID"
    
    if [ $? -ne 0 ]; then
        write_error "Failed to set subscription"
        return 1
    fi
    
    SUB_NAME=$(az account show --output json | jq -r '.name')
    write_success "Active subscription: $SUB_NAME"
    return 0
}

# ====================================
# Quota & Capacity Validation
# ====================================

test_appservice_quota() {
    local REGION=$1
    
    write_section "Checking App Service Quota"
    
    # Get provider registrations
    write_info "Checking Microsoft.Web provider registration..."
    PROVIDER_STATE=$(az provider show --namespace Microsoft.Web --output json 2>/dev/null | jq -r '.registrationState' 2>/dev/null)
    
    if [ "$PROVIDER_STATE" != "Registered" ]; then
        write_warning "Microsoft.Web provider not registered. Registering..."
        az provider register --namespace Microsoft.Web
        write_info "Provider registration initiated (this may take 5-10 minutes)"
    else
        write_success "Microsoft.Web provider is registered"
    fi
    
    # Check VMs quota for the region
    write_info "Checking Total vCores quota in region: $REGION"
    
    write_warning "Quota check requires Azure Portal access"
    write_info "To verify App Service capacity for $REGION:"
    write_info "  1. Go to https://portal.azure.com"
    write_info "  2. Search for 'Subscriptions' > Select your subscription"
    write_info "  3. Go to 'Usage + quotas' on the left panel"
    write_info "  4. Filter by Region: '$REGION' and Service: 'App Service'"
    write_info "  5. Verify 'Total vCores' limit >= 1 (current: check Current Value)"
    
    return 0
}

# ====================================
# Resource Creation (Path A & B)
# ====================================

new_resource_group() {
    local RG_NAME=$1
    local REGION=$2
    
    write_section "Creating Resource Group"
    
    # Check if already exists
    if az group exists --name "$RG_NAME" --output json | jq -e 'true' &>/dev/null; then
        write_success "Resource group already exists: $RG_NAME"
        return 0
    fi
    
    write_info "Creating resource group: $RG_NAME in region: $REGION"
    az group create --name "$RG_NAME" --location "$REGION"
    
    if [ $? -ne 0 ]; then
        write_error "Failed to create resource group"
        return 1
    fi
    
    write_success "Resource group created: $RG_NAME"
    return 0
}

new_appservice_plan() {
    local RG_NAME=$1
    local PLAN_NAME=$2
    local REGION=$3
    local SKU=$4
    
    write_section "Creating App Service Plan"
    
    # Check if already exists
    if az appservice plan show --resource-group "$RG_NAME" --name "$PLAN_NAME" &>/dev/null; then
        write_success "App Service plan already exists: $PLAN_NAME"
        return 0
    fi
    
    write_info "Creating App Service plan: $PLAN_NAME"
    write_info "  SKU: $SKU (1 vCore, 1 GB RAM)"
    write_info "  Region: $REGION"
    write_info "  OS: Linux"
    
    az appservice plan create \
        --name "$PLAN_NAME" \
        --resource-group "$RG_NAME" \
        --location "$REGION" \
        --sku "$SKU" \
        --is-linux
    
    if [ $? -ne 0 ]; then
        write_error "Failed to create App Service plan"
        write_info "If quota error occurs, check the documented paths:"
        write_info "  Path A: Assign subscription to JayPVentures LLC tenant"
        write_info "  Path B: Request quota increase in Azure Portal"
        write_info "  Path C: Use alternate runtime host (Render, Railway, Fly.io)"
        return 1
    fi
    
    write_success "App Service plan created: $PLAN_NAME"
    return 0
}

new_webapp() {
    local RG_NAME=$1
    local APP_NAME=$2
    local PLAN_NAME=$3
    
    write_section "Creating Web App"
    
    # Check if already exists
    if az webapp show --resource-group "$RG_NAME" --name "$APP_NAME" &>/dev/null; then
        write_success "Web app already exists: $APP_NAME"
        return 0
    fi
    
    write_info "Creating Web app: $APP_NAME"
    write_info "  Runtime: .NET 8"
    write_info "  OS: Linux"
    
    az webapp create \
        --resource-group "$RG_NAME" \
        --plan "$PLAN_NAME" \
        --name "$APP_NAME" \
        --runtime "DOTNET|8.0"
    
    if [ $? -ne 0 ]; then
        write_error "Failed to create Web app"
        return 1
    fi
    
    write_success "Web app created: $APP_NAME"
    return 0
}

enable_https_only() {
    local RG_NAME=$1
    local APP_NAME=$2
    
    write_section "Configuring HTTPS"
    
    az webapp update \
        --resource-group "$RG_NAME" \
        --name "$APP_NAME" \
        --set httpsOnly=true
    
    if [ $? -eq 0 ]; then
        write_success "HTTPS enforced for web app"
    else
        write_warning "Could not enforce HTTPS (may require further configuration)"
    fi
}

get_publish_profile() {
    local RG_NAME=$1
    local APP_NAME=$2
    local PROFILE_PATH="$SCRIPT_DIR/azure-publish-profile-$APP_NAME.xml"
    
    write_section "Generating Publish Profile"
    
    write_info "Downloading publish profile to: $PROFILE_PATH"
    az webapp deployment list-publishing-profiles \
        --resource-group "$RG_NAME" \
        --name "$APP_NAME" \
        --xml > "$PROFILE_PATH"
    
    if [ $? -ne 0 ]; then
        write_error "Failed to download publish profile"
        return 1
    fi
    
    # Verify file was created
    if [ ! -f "$PROFILE_PATH" ]; then
        write_error "Publish profile file not created"
        return 1
    fi
    
    local FILE_SIZE=$(wc -c < "$PROFILE_PATH")
    write_success "Publish profile generated: $PROFILE_PATH ($FILE_SIZE bytes)"
    
    echo "$PROFILE_PATH"
    return 0
}

register_publish_profile_secret() {
    local PROFILE_PATH=$1
    local APP_NAME=$2
    
    write_section "Registering GitHub Secret"
    
    if ! command -v gh &> /dev/null; then
        write_warning "GitHub CLI not found. Manual secret registration required."
        write_info "To register the publish profile secret:"
        write_info "  Using PowerShell (recommended for special characters):"
        write_info "    Get-Content -Raw '$PROFILE_PATH' | gh secret set AZURE_WEBAPP_PUBLISH_PROFILE --body-file -"
        write_info ""
        write_info "  Using Bash:"
        write_info "    cat '$PROFILE_PATH' | gh secret set AZURE_WEBAPP_PUBLISH_PROFILE --body-file -"
        return 1
    fi
    
    write_info "Registering AZURE_WEBAPP_PUBLISH_PROFILE secret..."
    
    # Use pipe with gh
    cat "$PROFILE_PATH" | gh secret set AZURE_WEBAPP_PUBLISH_PROFILE --body-file -
    
    if [ $? -eq 0 ]; then
        write_success "GitHub secret registered: AZURE_WEBAPP_PUBLISH_PROFILE"
        return 0
    else
        write_warning "Failed to register GitHub secret (may require manual registration)"
        return 1
    fi
}

# ====================================
# Path C: Alternate Runtimes
# ====================================

test_alternate_runtimes() {
    write_section "Path C: Alternate Runtime Options"
    
    write_info "Validated runtime hosts for .NET 8 deployment:\n"
    
    # Fly.io
    write_info "1. Fly.io (Recommended for quick start)"
    write_info "   Command: fly auth login && fly deploy"
    write_info "   Config: fly.toml (already configured)"
    if [ -f "$REPO_ROOT/fly.toml" ]; then
        write_success "   fly.toml found in repository"
    fi
    
    # Render
    write_info ""
    write_info "2. Render"
    write_info "   Command: render deploy"
    write_info "   Config: render.yaml (already configured)"
    if [ -f "$REPO_ROOT/render.yaml" ]; then
        write_success "   render.yaml found in repository"
    fi
    
    # Railway
    write_info ""
    write_info "3. Railway"
    write_info "   Command: railway deploy"
    write_info "   Supports Docker deployment"
    
    # DigitalOcean App Platform
    write_info ""
    write_info "4. DigitalOcean App Platform"
    write_info "   Supports Docker deployment"
    write_info "   More info: https://docs.digitalocean.com/products/app-platform/"
    
    # AWS App Runner
    write_info ""
    write_info "5. AWS App Runner"
    write_info "   Supports container image deployment"
    write_info "   More info: https://aws.amazon.com/apprunner/"
    
    write_info ""
    write_info "See docs/CONTAINER-DEPLOYMENT.md for detailed instructions."
    
    return 0
}

# ====================================
# Validation Summary
# ====================================

test_deployment_prerequisites() {
    local RG_NAME=$1
    local APP_NAME=$2
    
    write_section "Validating Deployment Prerequisites"
    
    local ALL_GOOD=true
    
    # Test health endpoint availability
    write_info "Checking health endpoint configuration..."
    local PROJ_PATH="$REPO_ROOT/src/JPVOS/Program.cs"
    if grep -q "health" "$PROJ_PATH"; then
        write_success "Health endpoint configured at /health"
    else
        write_error "Health endpoint not found in Program.cs"
        ALL_GOOD=false
    fi
    
    # Check resource availability
    if [ -n "$RG_NAME" ] && [ -n "$APP_NAME" ]; then
        write_info "Checking Azure resources..."
        
        # Check resource group
        if az group show --name "$RG_NAME" &>/dev/null; then
            write_success "Resource group exists: $RG_NAME"
        else
            write_error "Resource group not found: $RG_NAME"
            ALL_GOOD=false
        fi
        
        # Check web app
        if az webapp show --resource-group "$RG_NAME" --name "$APP_NAME" &>/dev/null; then
            write_success "Web app exists: $APP_NAME"
            DEFAULT_HOSTNAME=$(az webapp show --resource-group "$RG_NAME" --name "$APP_NAME" --output json | jq -r '.defaultHostName')
            RUNTIME=$(az webapp show --resource-group "$RG_NAME" --name "$APP_NAME" --output json | jq -r '.linuxFxVersion')
            write_info "  URL: $DEFAULT_HOSTNAME"
            write_info "  Runtime: $RUNTIME"
        else
            write_error "Web app not found: $APP_NAME"
            ALL_GOOD=false
        fi
    fi
    
    if [ "$ALL_GOOD" = true ]; then
        return 0
    else
        return 1
    fi
}

# ====================================
# Main Execution
# ====================================

main() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═════════════════════════════════════════════════════════════╗
║    JPV-OS Access Gateway - Azure App Service Provisioning   ║
╚═════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    write_info "Path: $PATH_OPTION | Region: $REGION | SKU: $SKU_SIZE"
    
    # Step 1: Validate prerequisites
    if ! test_prerequisites; then
        exit 1
    fi
    
    # Step 2: Authentication
    if ! test_azure_login "$TENANT_ID"; then
        exit 1
    fi
    
    # Step 3: Subscription
    if [ "$PATH_OPTION" = "A" ] || [ "$PATH_OPTION" = "B" ]; then
        if [ -z "$SUBSCRIPTION_ID" ]; then
            write_error "SubscriptionId required for Path A and B"
            
            if get_available_subscriptions; then
                write_info "Use one of the available subscription IDs above:"
                write_info "  ./provision-azure-appservice.sh -Path $PATH_OPTION -SubscriptionId '<subscription-id>'"
            fi
            exit 1
        fi
        
        if ! set_active_subscription "$SUBSCRIPTION_ID"; then
            exit 1
        fi
    fi
    
    # Step 4: Quota check
    if [ "$PATH_OPTION" = "A" ] || [ "$PATH_OPTION" = "B" ]; then
        test_appservice_quota "$REGION"
    fi
    
    # If validation only, stop here
    if [ "$VALIDATE_ONLY" = true ]; then
        write_success "Validation complete"
        
        # Additional validation for existing resources
        test_deployment_prerequisites "$RESOURCE_GROUP" "$WEB_APP_NAME"
        exit 0
    fi
    
    # Step 5: Path A/B - Create resources
    if [ "$PATH_OPTION" = "A" ]; then
        write_section "Path A: JayPVentures LLC Tenant Subscription"
        write_info "Provisioning resources using JayPVentures LLC tenant..."
        
        if ! new_resource_group "$RESOURCE_GROUP" "$REGION"; then
            exit 1
        fi
        
        if ! new_appservice_plan "$RESOURCE_GROUP" "$APP_SERVICE_PLAN" "$REGION" "$SKU_SIZE"; then
            exit 1
        fi
        
        if ! new_webapp "$RESOURCE_GROUP" "$WEB_APP_NAME" "$APP_SERVICE_PLAN"; then
            exit 1
        fi
        
        enable_https_only "$RESOURCE_GROUP" "$WEB_APP_NAME"
        
        PROFILE_PATH=$(get_publish_profile "$RESOURCE_GROUP" "$WEB_APP_NAME")
        if [ -n "$PROFILE_PATH" ]; then
            register_publish_profile_secret "$PROFILE_PATH" "$WEB_APP_NAME"
        fi
    elif [ "$PATH_OPTION" = "B" ]; then
        write_section "Path B: Existing Subscription Quota"
        write_info "Using existing subscription with verified quota..."
        
        if ! new_resource_group "$RESOURCE_GROUP" "$REGION"; then
            exit 1
        fi
        
        if ! new_appservice_plan "$RESOURCE_GROUP" "$APP_SERVICE_PLAN" "$REGION" "$SKU_SIZE"; then
            write_error "Quota insufficient. Request quota increase at:"
            write_info "  https://portal.azure.com > Subscriptions > Usage + quotas"
            exit 1
        fi
        
        if ! new_webapp "$RESOURCE_GROUP" "$WEB_APP_NAME" "$APP_SERVICE_PLAN"; then
            exit 1
        fi
        
        enable_https_only "$RESOURCE_GROUP" "$WEB_APP_NAME"
        
        PROFILE_PATH=$(get_publish_profile "$RESOURCE_GROUP" "$WEB_APP_NAME")
        if [ -n "$PROFILE_PATH" ]; then
            register_publish_profile_secret "$PROFILE_PATH" "$WEB_APP_NAME"
        fi
    elif [ "$PATH_OPTION" = "C" ]; then
        write_section "Path C: Alternate Runtime Host"
        test_alternate_runtimes
    fi
    
    # Step 6: Final validation
    write_section "Provisioning Summary"
    
    if [ "$PATH_OPTION" = "A" ] || [ "$PATH_OPTION" = "B" ]; then
        if test_deployment_prerequisites "$RESOURCE_GROUP" "$WEB_APP_NAME"; then
            write_success "All prerequisites validated. Ready for deployment."
            write_info "Next steps:"
            write_info "  1. Configure app settings in Azure Portal"
            write_info "  2. Run GitHub Actions workflow: 'Deploy to Azure App Service'"
            write_info "  3. Monitor deployment at: https://portal.azure.com"
        fi
    fi
}

main
