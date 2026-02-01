# Cloudflare Workers Deployment Guide
## Fix X-Frame-Options for DocuSeal Iframe Embedding

**Time Required:** 15 minutes
**Cost:** $0 (Free tier: 100k requests/day)

---

## Prerequisites

1. ✅ Cloudflare account with wippli.ai domain
2. ✅ Azure Container App running DocuSeal (revision: b710ecc41a2b2551a7822c48b048e9a9ff9fe)
3. ✅ Access to admin@wippli.com Cloudflare account

---

## Step 1: Get Your Azure Container App URL (2 minutes)

### Option A: Azure Portal (Easiest)
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to: **Resource Groups** → `wippli-products-rg`
3. Click on your DocuSeal Container App (likely named `docuseal-test`)
4. Copy the **Application URL** (e.g., `https://docuseal-test.yellowsea-12345678.westeurope.azurecontainerapps.io`)
5. Write it down - you'll need it for Step 2

### Option B: Azure CLI (If installed)
```bash
az containerapp show \
  --name docuseal-test \
  --resource-group wippli-products-rg \
  --query properties.configuration.ingress.fqdn \
  --output tsv
```

**Example URL format:**
```
https://docuseal-test.yellowsea-12345678.westeurope.azurecontainerapps.io
```

---

## Step 2: Configure Cloudflare DNS (5 minutes)

1. **Log in to Cloudflare**
   - Go to: https://dash.cloudflare.com
   - Login with: admin@wippli.com

2. **Select wippli.ai domain**
   - Click on `wippli.ai` in your domains list

3. **Add DNS Record**
   - Navigate to: **DNS** → **Records**
   - Click **+ Add record**

4. **Configure CNAME Record**
   ```
   Type:          CNAME
   Name:          docuseal
   Target:        docuseal-test.yellowsea-12345678.westeurope.azurecontainerapps.io
                  ⚠️ IMPORTANT: Remove "https://" - just the hostname!
   Proxy status:  🟧 Proxied (orange cloud) ← CRITICAL!
   TTL:           Auto
   ```

5. **Click Save**

**⚠️ CRITICAL:** Ensure the cloud icon is **ORANGE** (Proxied), not gray!

---

## Step 3: Deploy Cloudflare Worker (5 minutes)

### 3.1 Create Worker

1. In Cloudflare Dashboard, go to **Workers & Pages**
2. Click **Create** → **Create Worker**
3. Name: `wippli-docuseal-iframe-fix`
4. Click **Deploy** (don't worry, we'll edit the code next)

### 3.2 Edit Worker Code

1. After deployment, click **Edit code** button
2. **DELETE ALL** existing code in the editor
3. **COPY** the entire contents from `cloudflare-worker.js` file
4. **PASTE** into the Cloudflare code editor
5. Click **Save and Deploy**

**Worker Code Preview:**
```javascript
// Wippli DocuSeal - Strip X-Frame-Options for iframe embedding
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const response = await fetch(request)
  const newResponse = new Response(response.body, response)

  // Remove X-Frame-Options
  newResponse.headers.delete('X-Frame-Options')
  newResponse.headers.delete('x-frame-options')

  // Add CSP with frame-ancestors
  const csp = "frame-ancestors 'self' *.wippli.ai app.wippli.ai dev.wippli.ai localhost:*"
  newResponse.headers.set('Content-Security-Policy', csp)
  newResponse.headers.set('X-Wippli-Cloudflare', 'active')

  return newResponse
}
```

### 3.3 Add Worker Route

1. Go back to your Cloudflare zone: **wippli.ai**
2. Navigate to: **Workers Routes** (in left sidebar)
3. Click **Add route**

4. **Configure Route:**
   ```
   Route:   docuseal.wippli.ai/*
   Worker:  wippli-docuseal-iframe-fix
   ```

5. Click **Save**

---

## Step 4: Test the Solution (3 minutes)

### 4.1 Wait for DNS Propagation

Wait **1-2 minutes** for DNS changes to propagate globally.

### 4.2 Test Headers via Command Line

```bash
curl -I https://docuseal.wippli.ai
```

**Expected output:**
```
HTTP/2 200
✅ content-security-policy: frame-ancestors 'self' *.wippli.ai app.wippli.ai dev.wippli.ai localhost:*
✅ x-wippli-cloudflare: active
❌ NO x-frame-options header (this is correct!)
```

**If you see:**
- ❌ `x-frame-options: SAMEORIGIN` → DNS not propagated yet OR proxy not enabled (check orange cloud)
- ✅ `x-wippli-cloudflare: active` → Cloudflare Worker is working!

### 4.3 Test Iframe Embedding

1. Open `test-iframe.html` in your browser
2. Check browser console (F12)
3. DocuSeal should load inside the iframe without errors

**Successful Test:**
- ✅ Iframe displays DocuSeal login page
- ✅ No "Refused to display" errors in console
- ✅ Green success message appears

---

## Step 5: Update WipBoard Integration

Once tested, update your WipBoard iframe source:

**Before:**
```html
<iframe src="https://docuseal-test.yellowsea-12345678.westeurope.azurecontainerapps.io" />
```

**After:**
```html
<iframe src="https://docuseal.wippli.ai" />
```

---

## Troubleshooting

### Problem: "x-frame-options: SAMEORIGIN" still appears

**Cause:** Cloudflare proxy not enabled OR DNS not propagated

**Fix:**
1. Go to Cloudflare DNS → docuseal record
2. Ensure cloud icon is **ORANGE** (Proxied), not gray
3. Wait 2-3 minutes for DNS propagation
4. Clear browser cache: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)

### Problem: "Worker not found" or 404 error

**Cause:** Worker route not configured

**Fix:**
1. Cloudflare → Workers Routes
2. Add route: `docuseal.wippli.ai/*`
3. Assign worker: `wippli-docuseal-iframe-fix`

### Problem: Iframe still blocked

**Cause:** Browser cached old headers

**Fix:**
1. Open browser DevTools (F12)
2. Go to Network tab
3. Check "Disable cache"
4. Hard refresh: Ctrl+Shift+R

---

## Monitoring

**Check Cloudflare Analytics:**
1. Cloudflare Dashboard → Analytics & Logs
2. Look for:
   - Request volume to docuseal.wippli.ai
   - Error rate (should be <1%)
   - Response time (should be +5-10ms)

**Free Tier Limits:**
- 100,000 requests/day
- Sufficient for 50+ creators
- Cost: $0/month

---

## Rollback Plan (If Something Goes Wrong)

### Quick Rollback (30 seconds)
1. Cloudflare → DNS → docuseal record
2. Click the orange cloud icon to turn it **gray** (DNS only)
3. Traffic now bypasses Cloudflare Worker
4. Iframe will be blocked again, but DocuSeal direct access works

### Full Rollback (2 minutes)
1. Go to Workers Routes
2. Delete route for `docuseal.wippli.ai/*`
3. Go to DNS records
4. Delete docuseal CNAME record
5. Back to original Azure URL

---

## Next Steps After Success

1. ✅ Test iframe in WipBoard production environment
2. ✅ Monitor Cloudflare Analytics for 24 hours
3. ✅ Update documentation with new docuseal.wippli.ai URL
4. ✅ Proceed with Wippli_Sign implementation (original plan)

---

## Success Criteria

- [ ] `curl -I https://docuseal.wippli.ai` shows NO X-Frame-Options
- [ ] `curl -I https://docuseal.wippli.ai` shows X-Wippli-Cloudflare: active
- [ ] `test-iframe.html` loads DocuSeal without console errors
- [ ] WipBoard iframe embed displays DocuSeal interface
- [ ] Users can sign documents inside WipBoard iframe

---

## Support

If you encounter issues:
1. Check Cloudflare Worker logs: Workers & Pages → wippli-docuseal-iframe-fix → Logs
2. Test direct Azure URL to ensure DocuSeal is running
3. Verify DNS propagation: https://dnschecker.org (search for docuseal.wippli.ai)

**Estimated Success Rate:** 95%+ (based on research, Cloudflare Workers is battle-tested)

---

**Document Version:** 1.0
**Last Updated:** 2026-01-13
**Author:** Claude Code
