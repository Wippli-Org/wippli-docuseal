#!/bin/bash
# Quick script to get Azure Container App URL

echo "🔍 Getting Azure Container App URL..."
echo ""

# Try to find Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not installed"
    echo ""
    echo "Install with:"
    echo "  brew install azure-cli"
    echo ""
    echo "Or:"
    echo "  curl -L https://aka.ms/InstallAzureCli | bash"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null 2>&1; then
    echo "🔐 Logging in to Azure..."
    az login
fi

echo ""
echo "📋 Listing all Container Apps in wippli-products-rg..."
echo ""

az containerapp list \
    --resource-group wippli-products-rg \
    --query "[].{Name:name, URL:properties.configuration.ingress.fqdn, State:properties.runningStatus}" \
    --output table

echo ""
echo "📍 DocuSeal Container App URL:"
echo ""

URL=$(az containerapp show \
    --name docuseal-test \
    --resource-group wippli-products-rg \
    --query "properties.configuration.ingress.fqdn" \
    --output tsv 2>/dev/null)

if [ -n "$URL" ]; then
    echo "✅ https://$URL"
    echo ""
    echo "Use this for Cloudflare DNS CNAME target: $URL"
else
    echo "❌ Container App 'docuseal-test' not found"
    echo ""
    echo "Try one of the URLs listed above"
fi

echo ""
