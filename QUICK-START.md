# 🚀 Quick Start: Fix DocuSeal Iframe Embedding (5 Commands)

**Time:** 10-15 minutes | **Cost:** $0

---

## Prerequisites Check

```bash
# Install Azure CLI (if not installed)
brew install azure-cli

# OR for Linux/manual install:
curl -L https://aka.ms/InstallAzureCli | bash

# Install Wrangler (Cloudflare CLI) - optional
npm install -g wrangler
```

---

## Step 1: Get Azure Container App URL (2 minutes)

```bash
# Login to Azure
az login

# Get the URL
az containerapp show \
  --name docuseal-test \
  --resource-group wippli-products-rg \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv
```

**Expected output:**
```
docuseal-test.yellowsea-abc12345.westeurope.azurecontainerapps.io
```

**Copy this URL** - you'll need it for Step 2!

---

## Step 2: Configure Cloudflare DNS (3 minutes)

### Manual (Easiest - via Dashboard)

1. Go to: https://dash.cloudflare.com
2. Login with: **admin@wippli.com**
3. Click domain: **wippli.ai**
4. Click: **DNS** → **Records** → **+ Add record**

5. Fill in:
   ```
   Type:          CNAME
   Name:          docuseal
   Target:        [PASTE URL FROM STEP 1]
   Proxy status:  🟧 Proxied (ORANGE cloud) ⚠️ CRITICAL!
   TTL:           Auto
   ```

6. Click **Save**

### OR via Cloudflare API (Advanced)

```bash
# Set variables
CLOUDFLARE_EMAIL="admin@wippli.com"
CLOUDFLARE_API_KEY="your-global-api-key"  # Get from Cloudflare dashboard
ZONE_ID="your-zone-id"  # Get from wippli.ai zone overview
AZURE_URL="docuseal-test.yellowsea-abc12345.westeurope.azurecontainerapps.io"

# Create DNS record
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "docuseal",
    "content": "'"$AZURE_URL"'",
    "proxied": true,
    "ttl": 1
  }'
```

---

## Step 3: Deploy Cloudflare Worker (5 minutes)

### Option A: Via Dashboard (Easiest)

1. Go to: https://dash.cloudflare.com
2. Navigate to: **Workers & Pages** → **Create** → **Create Worker**
3. Name: `wippli-docuseal-iframe-fix`
4. Click **Deploy**

5. Click **Edit code**
6. **Delete all existing code**
7. Open `cloudflare-worker.js` in this directory
8. **Copy and paste the entire content** into the editor
9. Click **Save and Deploy**

10. Go to: **Workers & Pages** → `wippli-docuseal-iframe-fix` → **Settings** → **Triggers**
11. Click **Add route**
12. Enter route: `docuseal.wippli.ai/*`
13. Select zone: `wippli.ai`
14. Click **Save**

### Option B: Via Wrangler CLI (Advanced)

```bash
cd wippli-docuseal

# Login to Cloudflare
wrangler login

# Deploy
wrangler deploy
```

---

## Step 4: Test Deployment (3 minutes)

### Wait for DNS Propagation

```bash
# Wait 60 seconds
sleep 60
```

### Test Headers

```bash
# Check that X-Frame-Options is removed
curl -I https://docuseal.wippli.ai | grep -iE '(x-frame|content-security|x-wippli)'
```

**Expected output:**
```
✅ content-security-policy: frame-ancestors 'self' *.wippli.ai ...
✅ x-wippli-cloudflare: active
❌ NO x-frame-options line (this is correct!)
```

### Test Iframe

```bash
# Open test page in browser
open test-iframe.html
```

**Expected:**
- ✅ DocuSeal loads inside iframe
- ✅ No "Refused to display" errors in console
- ✅ Green success message appears

---

## Step 5: Update WipBoard (1 minute)

Change iframe src from:
```html
<!-- OLD (direct Azure URL) -->
<iframe src="https://docuseal-test.yellowsea-abc12345.westeurope.azurecontainerapps.io" />
```

To:
```html
<!-- NEW (via Cloudflare) -->
<iframe src="https://docuseal.wippli.ai" />
```

---

## ✅ Success Criteria

Run this final check:

```bash
# All-in-one test
echo "Testing headers..." && \
curl -sI https://docuseal.wippli.ai | grep -qi "x-wippli-cloudflare" && echo "✅ Worker active" || echo "❌ Worker not active" && \
curl -sI https://docuseal.wippli.ai | grep -qi "x-frame-options" && echo "❌ X-Frame-Options still present" || echo "✅ X-Frame-Options removed" && \
curl -sI https://docuseal.wippli.ai | grep -qi "frame-ancestors" && echo "✅ CSP with frame-ancestors added" || echo "❌ No frame-ancestors in CSP"
```

**All checks should show ✅**

---

## Troubleshooting

### "Worker not active"

**Fix:**
1. Cloudflare Dashboard → DNS → docuseal record
2. Ensure cloud is **ORANGE** (Proxied), not gray
3. Wait 2 minutes, test again

### "X-Frame-Options still present"

**Fix:**
1. Clear browser cache: Ctrl+Shift+R (Windows) / Cmd+Shift+R (Mac)
2. Check Worker route: `docuseal.wippli.ai/*`
3. Verify Worker code matches `cloudflare-worker.js`

### DNS not resolving

**Check propagation:**
```bash
# Check DNS
dig docuseal.wippli.ai

# OR
nslookup docuseal.wippli.ai
```

Wait 5 minutes if newly created, then retry.

---

## Rollback (If Needed)

```bash
# Quick rollback - disable proxy
# Go to Cloudflare DNS → docuseal record
# Click orange cloud to make it gray (DNS only)
```

---

## Next Steps

1. ✅ Test in WipBoard production
2. ✅ Monitor Cloudflare Analytics for 24 hours
3. ✅ Document new docuseal.wippli.ai URL for team
4. ✅ Proceed with Wippli_Sign implementation

---

## Support

**Files in this directory:**
- `cloudflare-worker.js` - Worker code
- `test-iframe.html` - Test page
- `CLOUDFLARE-DEPLOYMENT.md` - Detailed guide
- `deploy-cloudflare.sh` - Automated script (requires Az CLI + Wrangler)

**Need help?**
- Cloudflare logs: Workers & Pages → wippli-docuseal-iframe-fix → Logs
- Azure logs: Container Apps → docuseal-test → Log stream
- DNS check: https://dnschecker.org (search: docuseal.wippli.ai)

---

**Ready? Start with Step 1! 🚀**
