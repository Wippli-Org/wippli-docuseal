#!/bin/bash
# Wippli DocuSeal - Cloudflare Workers Deployment Script
# This script automates the deployment of Cloudflare Workers to fix iframe embedding

set -e  # Exit on any error

echo "🚀 Wippli DocuSeal - Cloudflare Workers Deployment"
echo "=================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="wippli-products-rg"
CONTAINER_APP_NAME="docuseal-test"
CLOUDFLARE_SUBDOMAIN="docuseal"
CLOUDFLARE_DOMAIN="wippli.ai"

# Step 1: Check Azure CLI installation
echo "📋 Step 1: Checking Azure CLI..."
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found${NC}"
    echo ""
    echo "Installing Azure CLI..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew update && brew install azure-cli
        else
            echo -e "${YELLOW}⚠️  Homebrew not found. Installing via curl...${NC}"
            curl -L https://aka.ms/InstallAzureCli | bash
        fi
    else
        # Linux
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    fi
    echo -e "${GREEN}✅ Azure CLI installed${NC}"
else
    echo -e "${GREEN}✅ Azure CLI found${NC}"
fi

echo ""

# Step 2: Login to Azure
echo "🔐 Step 2: Azure Login..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure..."
    az login
else
    echo -e "${GREEN}✅ Already logged in to Azure${NC}"
    ACCOUNT=$(az account show --query user.name -o tsv)
    echo "   Account: $ACCOUNT"
fi

echo ""

# Step 3: Get Container App URL
echo "🔍 Step 3: Getting Azure Container App URL..."
CONTAINER_URL=$(az containerapp show \
    --name "$CONTAINER_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.configuration.ingress.fqdn" \
    --output tsv 2>/dev/null || echo "")

if [ -z "$CONTAINER_URL" ]; then
    echo -e "${RED}❌ Failed to get Container App URL${NC}"
    echo ""
    echo "Please verify:"
    echo "  - Resource Group: $RESOURCE_GROUP"
    echo "  - Container App: $CONTAINER_APP_NAME"
    echo ""
    echo "List all container apps:"
    az containerapp list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, URL:properties.configuration.ingress.fqdn}" --output table
    exit 1
fi

echo -e "${GREEN}✅ Container App URL found${NC}"
echo "   URL: https://$CONTAINER_URL"
echo ""

# Step 4: Check Cloudflare CLI
echo "📋 Step 4: Checking Cloudflare CLI (Wrangler)..."
if ! command -v wrangler &> /dev/null; then
    echo -e "${YELLOW}⚠️  Cloudflare Wrangler not found. Installing...${NC}"
    npm install -g wrangler
    echo -e "${GREEN}✅ Wrangler installed${NC}"
else
    echo -e "${GREEN}✅ Wrangler found${NC}"
fi

echo ""

# Step 5: Show Cloudflare DNS Configuration
echo "🌐 Step 5: Cloudflare DNS Configuration"
echo "========================================"
echo ""
echo "⚠️  MANUAL ACTION REQUIRED:"
echo ""
echo "1. Go to: https://dash.cloudflare.com"
echo "2. Login with: admin@wippli.com"
echo "3. Select domain: $CLOUDFLARE_DOMAIN"
echo "4. Navigate to: DNS → Records"
echo "5. Click: + Add record"
echo ""
echo "6. Configure CNAME record:"
echo -e "   ${YELLOW}Type:${NC}          CNAME"
echo -e "   ${YELLOW}Name:${NC}          $CLOUDFLARE_SUBDOMAIN"
echo -e "   ${YELLOW}Target:${NC}        $CONTAINER_URL"
echo -e "   ${YELLOW}Proxy status:${NC}  ☁️  Proxied (ORANGE cloud) ← CRITICAL!"
echo -e "   ${YELLOW}TTL:${NC}           Auto"
echo ""
echo "7. Click: Save"
echo ""
echo -n "Press Enter when DNS is configured..."
read

echo ""

# Step 6: Deploy Cloudflare Worker
echo "🚀 Step 6: Deploying Cloudflare Worker..."
echo "========================================="
echo ""

# Create wrangler.toml configuration
cat > wrangler.toml <<EOF
name = "wippli-docuseal-iframe-fix"
main = "cloudflare-worker.js"
compatibility_date = "2024-01-01"

[env.production]
routes = [
  { pattern = "$CLOUDFLARE_SUBDOMAIN.$CLOUDFLARE_DOMAIN/*", zone_name = "$CLOUDFLARE_DOMAIN" }
]
EOF

echo "Created wrangler.toml configuration"
echo ""
echo "⚠️  MANUAL ACTION REQUIRED:"
echo ""
echo "To deploy the worker, run:"
echo ""
echo -e "   ${YELLOW}wrangler login${NC}"
echo -e "   ${YELLOW}wrangler deploy${NC}"
echo ""
echo "OR deploy manually via Cloudflare Dashboard:"
echo ""
echo "1. Go to: https://dash.cloudflare.com"
echo "2. Navigate to: Workers & Pages → Create"
echo "3. Name: wippli-docuseal-iframe-fix"
echo "4. Copy code from: cloudflare-worker.js"
echo "5. Deploy"
echo "6. Add route: $CLOUDFLARE_SUBDOMAIN.$CLOUDFLARE_DOMAIN/*"
echo ""
echo -n "Press Enter when Worker is deployed..."
read

echo ""

# Step 7: Test the deployment
echo "🧪 Step 7: Testing Deployment..."
echo "================================"
echo ""

FULL_URL="https://$CLOUDFLARE_SUBDOMAIN.$CLOUDFLARE_DOMAIN"

echo "Waiting 30 seconds for DNS propagation..."
sleep 30

echo ""
echo "Testing headers..."
RESPONSE=$(curl -s -I "$FULL_URL" 2>/dev/null || echo "FAILED")

if echo "$RESPONSE" | grep -qi "x-wippli-cloudflare"; then
    echo -e "${GREEN}✅ Cloudflare Worker is active!${NC}"
else
    echo -e "${YELLOW}⚠️  Cloudflare Worker may not be active yet${NC}"
    echo "   DNS may still be propagating (can take 2-5 minutes)"
fi

if echo "$RESPONSE" | grep -qi "x-frame-options"; then
    echo -e "${RED}❌ X-Frame-Options header still present${NC}"
    echo "   Check that Cloudflare proxy is enabled (orange cloud)"
else
    echo -e "${GREEN}✅ X-Frame-Options header removed!${NC}"
fi

if echo "$RESPONSE" | grep -qi "content-security-policy"; then
    if echo "$RESPONSE" | grep -qi "frame-ancestors"; then
        echo -e "${GREEN}✅ Content-Security-Policy with frame-ancestors added!${NC}"
    else
        echo -e "${YELLOW}⚠️  CSP present but no frame-ancestors${NC}"
    fi
else
    echo -e "${RED}❌ No Content-Security-Policy header${NC}"
fi

echo ""
echo "Full headers check:"
curl -I "$FULL_URL" 2>/dev/null | grep -iE "(x-frame|content-security|x-wippli)" || echo "No relevant headers found"

echo ""
echo "================================"
echo "🎉 Deployment Complete!"
echo "================================"
echo ""
echo "📍 DocuSeal URL: $FULL_URL"
echo ""
echo "Next steps:"
echo "1. Open test-iframe.html in your browser"
echo "2. Update WipBoard iframe src to: $FULL_URL"
echo "3. Test document signing workflow"
echo ""
echo "To verify manually:"
echo "   curl -I $FULL_URL | grep -iE '(x-frame|content-security|x-wippli)'"
echo ""
echo "📊 Monitor at: https://dash.cloudflare.com"
echo ""
