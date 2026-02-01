# n8n WippliSign Workflow with Guest Token

**File**: `n8n-wippli-docuseal-workflow.json`
**Purpose**: Creates DocuSeal submissions with guest token URLs (no login required)

## Workflow Flow

```
Webhook → Creator Node → Create DocuSeal → Format Response → Return URL
  ↓           ↓              ↓                 ↓                ↓
Wippli     Get guest     Create PDF       Add guest_token   User opens PDF
payload      token       submission          to URL         (no login!)
```

## How to Import

1. Go to n8n playground: `https://n8n-playground.lemonriver-7e8b5f43.australiaeast.azurecontainerapps.io`
2. Click **"Import from File"**
3. Upload: `n8n-wippli-docuseal-workflow.json`
4. Configure credentials:
   - Add DocuSeal API key as `docusealApiKey`
5. Activate workflow

## What It Does

### 1. Receives Webhook from Wippli
**Expected payload:**
```json
{
  "wippliId": 1058,
  "user_name": "Admin Wippli",
  "nodesObject": {
    "user": {
      "id": 10,
      "email": "admin@wippli.com",
      "firstName": "Admin",
      "lastName": "Wippli"
    },
    "wippli": {
      "id": 1058,
      "productId": 53,
      "companyId": 18
    }
  },
  "templateId": 1
}
```

### 2. Calls Creator Node
**URL:** `https://wippli-creator-toolkit.../api/branding?productId=53&companyId=18`

**Gets back:**
```json
{
  "creator_product": {
    "id": 53,
    "name": "ProLo Chat",
    "guestToken": "77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03"
  },
  "creator_company": {
    "id": 18,
    "name": "proLogistik",
    "code": "9d20b11edb814f4efbb8"
  }
}
```

### 3. Creates DocuSeal Submission
**URL:** `https://docuseal.wippli.ai/api/submissions`

**Sends:**
```json
{
  "template_id": 1,
  "send_email": false,
  "recipients": [
    {
      "email": "admin@wippli.com",
      "name": "Admin Wippli",
      "role": "signer"
    }
  ],
  "metadata": {
    "wippli_id": 1058,
    "product_id": 53,
    "company_id": 18,
    "user_email": "admin@wippli.com"
  }
}
```

**Gets back:**
```json
{
  "id": 12345,
  "slug": "abc123def456",
  "template_id": 1,
  "created_at": "2026-01-30T11:00:00.000Z"
}
```

### 4. Formats Response with Guest Token
**Returns to Wippli:**
```json
{
  "success": true,
  "docuseal": {
    "url": "https://docuseal.wippli.ai/s/abc123def456?guest_token=77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03",
    "url_without_token": "https://docuseal.wippli.ai/s/abc123def456",
    "submission_id": 12345,
    "slug": "abc123def456"
  },
  "guest_token": "77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03",
  "wippli": {
    "id": 1058,
    "user_id": 10,
    "user_email": "admin@wippli.com",
    "user_name": "Admin Wippli",
    "product_id": 53,
    "company_id": 18
  },
  "branding": {
    "product_name": "ProLo Chat",
    "company_name": "proLogistik",
    "company_code": "9d20b11edb814f4efbb8"
  },
  "_timestamp": "2026-01-30T11:00:00.000Z",
  "_note": "URL with guest_token allows access without login"
}
```

## The Magic URL

**URL returned:**
```
https://docuseal.wippli.ai/s/abc123def456?guest_token=77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03
```

**What happens when user clicks:**
1. ✅ Guest token is validated (64-char hex)
2. ✅ User is marked as "guest authenticated"
3. ✅ PDF opens immediately
4. ✅ **No login required!**

## Configuration Required

### DocuSeal API Credential
In n8n, create credential:
- **Type:** Header Auth
- **Name:** `docusealApiKey`
- **Header Name:** `X-Auth-Token`
- **Header Value:** Your DocuSeal API key

### Template ID
Update the workflow if using a different template:
- Edit "Create DocuSeal Submission" node
- Change `template_id` value
- Or pass it in webhook payload as `templateId`

## Testing

### 1. Test via curl
```bash
curl -X POST https://n8n-playground.lemonriver-7e8b5f43.australiaeast.azurecontainerapps.io/webhook/wippli-docuseal \
  -H "Content-Type: application/json" \
  -d '{
    "wippliId": 1058,
    "user_name": "Test User",
    "templateId": 1,
    "nodesObject": {
      "user": {
        "id": 10,
        "email": "test@example.com",
        "firstName": "Test",
        "lastName": "User"
      },
      "wippli": {
        "id": 1058,
        "productId": 53,
        "companyId": 18
      }
    }
  }'
```

### 2. Expected Response
```json
{
  "success": true,
  "docuseal": {
    "url": "https://docuseal.wippli.ai/s/SLUG?guest_token=TOKEN"
  }
}
```

### 3. Test the URL
Copy the `docuseal.url` and open in browser:
- ✅ Should show PDF immediately
- ✅ No login page
- ✅ Ready to sign

## Troubleshooting

### Guest Token Not Working
1. Check DocuSeal logs for guest token validation
2. Verify token is 64-char hex string
3. Ensure URL has `?guest_token=` parameter

### Creator Node Error
1. Verify Creator Node is running
2. Check productId and companyId exist
3. Ensure guest token is in response

### DocuSeal API Error
1. Check API key is valid
2. Verify template_id exists
3. Check user email format

## Notes

- **Token Format**: Must be 64-character hexadecimal string
- **Parameter Names**: Supports both `guest_token` and `guestToken`
- **Validation**: Simple format validation (can be enhanced later)
- **Expiration**: Not implemented yet (tokens don't expire)
- **Revocation**: Not implemented yet

## Future Enhancements

1. **Token Expiration**: Add TTL to guest tokens
2. **Database Storage**: Store tokens with metadata
3. **Analytics**: Track guest token usage
4. **Rate Limiting**: Prevent token abuse
5. **One-time Use**: Tokens expire after first use
