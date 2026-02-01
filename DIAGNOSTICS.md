# Connection Diagnostics for docuseal.wippli.ai

## Current Status (Working from my end)
✅ HTTP 200
✅ X-Wippli-Cloudflare: active
✅ CSP: frame-ancestors configured
✅ No X-Frame-Options header

---

## If you see "refused to connect", try these:

### 1. Check DNS Resolution
Open Terminal and run:
```bash
nslookup docuseal.wippli.ai
```

**Expected output:**
```
Server:		8.8.8.8
Address:	8.8.8.8#53

Non-authoritative answer:
Name:	docuseal.wippli.ai
Address: 104.21.35.243
Name:	docuseal.wippli.ai
Address: 172.67.181.124
```

**If you see different IPs:** Your DNS is cached. Flush DNS:
```bash
# Mac
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder

# Windows
ipconfig /flushdns
```

### 2. Test with curl
```bash
curl -I https://docuseal.wippli.ai
```

**If curl works but browser doesn't:**
- Clear browser cache
- Try different browser
- Disable VPN/firewall temporarily

### 3. Test Direct IP Access
```bash
curl -I https://104.21.35.243 -H "Host: docuseal.wippli.ai"
```

### 4. Check Cloudflare Status
Visit: https://www.cloudflarestatus.com/
Make sure there are no outages in your region.

### 5. Test from Different Network
- Try mobile hotspot
- Try different wifi network
- This will confirm if it's your network/ISP blocking it

---

## Expected Cloudflare IPs
- **104.21.35.243** (IPv4 primary)
- **172.67.181.124** (IPv4 secondary)

If `nslookup` shows different IPs, your DNS hasn't updated yet.

---

## Quick Test Commands

```bash
# All-in-one diagnostic
echo "=== DNS Check ===" && \
nslookup docuseal.wippli.ai && \
echo "" && \
echo "=== HTTP Headers ===" && \
curl -I https://docuseal.wippli.ai 2>&1 | grep -E "(HTTP|x-frame|content-security|x-wippli)"
```

---

## If Nothing Works

**Wait 5-10 minutes** - DNS changes can take time to propagate globally.

Then try again in incognito mode: `Cmd+Shift+N` (Mac) or `Ctrl+Shift+N` (Windows)

---

## Working Alternative (Direct Azure URL)
If you need immediate access:
https://docuseal-test.whiteforest-41e4af0e.australiaeast.azurecontainerapps.io

⚠️ **Note:** This direct URL still has X-Frame-Options (won't work in iframe)
