# Guest Token Implementation for DocuSeal

**Date**: 2026-01-30
**Author**: Claude Code
**Status**: In Progress

## Overview

Implementing temporary guest token authentication to allow users to access DocuSeal forms/submissions without requiring login. This integrates with the Wippli Creator Node workflow.

## Token Structure from Payload

### Current Payload Field Names (Subject to Change)

**⚠️ IMPORTANT**: The payload field names may change in future iterations. Current implementation uses:

```json
{
  "guestToken": "77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03",
  "resultSecure": "https://app.wippli.ai/product/{productId}-{epoch}?guest_token={token}",
  "productId": 53,
  "companyId": 18,
  "epoch": 1769483473
}
```

### Potential Future Field Name Changes

| Current Field | Possible Alternatives | Notes |
|---------------|----------------------|-------|
| `guestToken` | `guest_token`, `accessToken`, `tempToken` | Monitor n8n workflow changes |
| `resultSecure` | `secure_url`, `secureLink`, `access_url` | URL format may also change |
| `productId` | `product_id`, `templateId` | ID reference structure |
| `companyId` | `company_id`, `organizationId` | Company identifier |
| `epoch` | `timestamp`, `expiresAt`, `ttl` | Time-based validation |

### Token Examples

**Token ending in 105ce (Brannium):**
```
Token: a60067b5905c9587588a71977d4aa9f4ab7d96f5c6a47c4a7e9222e7171105ce
Product: 72 (Docu Free)
Company: 8 (Brannium)
URL: https://app.wippli.ai/form/8/72?guest_token=a60067...105ce
```

**Token ending in 5e03 (ProLogistik):**
```
Token: 77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03
Product: 53 (ProLo Chat)
Company: 18 (proLogistik)
Company Code: 9d20b11edb814f4efbb8
URL: https://app.wippli.ai/form/18/53?guest_token=77245...5e03
```

## Implementation Plan

### Phase 1: Controller Modifications

#### 1. Start Form Controller (`app/controllers/start_form_controller.rb`)
- Add `guest_token` parameter support
- Validate token before authentication check
- Skip authentication when valid guest_token present
- Associate submission with guest token metadata

#### 2. Submit Form Controller (`app/controllers/submit_form_controller.rb`)
- Add `guest_token` parameter support
- Validate token for submission access
- Skip authentication when valid guest_token present

### Phase 2: Token Validation

#### Validation Strategy Options

**Option A: Database-backed (Recommended)**
- Store guest tokens in database table
- Validate against stored tokens
- Support expiration and revocation

**Option B: API Validation**
- Call Wippli Creator Node API to validate
- Real-time validation against source
- No local storage needed

**Option C: JWT/Signed Token**
- Self-contained validation
- No database/API needed
- Verify signature and expiration

### Phase 3: URL Structure

**DocuSeal Guest Token URLs:**
```
# Start Form (template/shared link)
https://docuseal.wippli.ai/d/{slug}?guest_token={token}

# Submit Form (submission)
https://docuseal.wippli.ai/s/{slug}?guest_token={token}
```

### Phase 4: Database Schema (Option A)

```ruby
create_table :guest_tokens do |t|
  t.string :token, null: false, index: { unique: true }
  t.string :token_type # 'wippli_product', 'temp_access', etc.
  t.integer :product_id
  t.integer :company_id
  t.string :company_code
  t.integer :epoch
  t.datetime :expires_at
  t.boolean :revoked, default: false
  t.jsonb :metadata # Store additional payload data
  t.timestamps
end
```

## Configuration

### Environment Variables

```bash
# Guest token validation method
GUEST_TOKEN_VALIDATION=database  # Options: database, api, jwt

# API validation endpoint (if using Option B)
WIPPLI_CREATOR_API_URL=https://wippli-creator-toolkit.lemonriver-7e8b5f43.australiaeast.azurecontainerapps.io

# Token expiration (in seconds)
GUEST_TOKEN_TTL=86400  # 24 hours default
```

## Security Considerations

1. **Token Storage**: Tokens should be hashed if stored in database
2. **Expiration**: All tokens must have expiration dates
3. **Revocation**: Support for revoking compromised tokens
4. **Rate Limiting**: Apply rate limits to guest token endpoints
5. **Audit Logging**: Log all guest token usage
6. **HTTPS Only**: Guest tokens only work over HTTPS in production

## Migration Path

### If Payload Field Names Change

1. Update controller parameter parsing
2. Update validation logic
3. Update documentation
4. Maintain backward compatibility for transition period
5. Add deprecation warnings for old field names

### Backward Compatibility

```ruby
# Example: Support both old and new field names
def extract_guest_token
  params[:guest_token] ||
  params[:guestToken] ||
  params[:access_token] ||
  params[:temp_token]
end
```

## Testing

### Test Cases

1. Valid guest token grants access without login
2. Expired token is rejected
3. Invalid token is rejected
4. Revoked token is rejected
5. Missing token requires login
6. Token works across different submission states

### Test URLs

```
# Valid token (ProLogistik)
https://docuseal.wippli.ai/s/{slug}?guest_token=77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03

# Valid token (Brannium)
https://docuseal.wippli.ai/s/{slug}?guest_token=a60067b5905c9587588a71977d4aa9f4ab7d96f5c6a47c4a7e9222e7171105ce
```

## n8n Workflow Integration

### Workflow: WippliSign_Official

The n8n workflow should:
1. Create DocuSeal submission via API
2. Receive submission slug in response
3. Extract guestToken from Creator Node payload
4. Form the temporary access URL
5. Return URL to user

### Example n8n Node Code

```javascript
// Extract from Creator Node
const guestToken = $node["Creator Node"].json.guestToken;
const productId = $node["Creator Node"].json.productId;
const companyId = $node["Creator Node"].json.companyId;

// Create DocuSeal submission
const docusealResponse = $node["Create DocuSeal Submission"].json;
const submissionSlug = docusealResponse.slug;

// Form temporary access URL
const accessUrl = `https://docuseal.wippli.ai/s/${submissionSlug}?guest_token=${guestToken}`;

return {
  accessUrl: accessUrl,
  submissionId: docusealResponse.id,
  guestToken: guestToken
};
```

## Monitoring

### Metrics to Track

- Guest token usage rate
- Token validation failures
- Token expiration rates
- Average session duration
- Conversion rate (guest → registered user)

## Future Enhancements

1. **Token Refresh**: Allow extending token expiration
2. **Multi-use Tokens**: Tokens that work across multiple submissions
3. **Scoped Permissions**: Limit token access to specific actions
4. **Analytics**: Track guest user behavior
5. **Auto-registration**: Convert guest sessions to full accounts

## References

- Payload source: `/Users/wippliair/Library/CloudStorage/OneDrive-Wippli/Wippli_Master_Microsoft/Wippli_Consulting/Wippli_ProLogistiks/n8n_debug_jan_2026/api_execution_1083_full.json`
- n8n playground: `https://n8n-playground.lemonriver-7e8b5f43.australiaeast.azurecontainerapps.io`
- Creator toolkit: `https://wippli-creator-toolkit.lemonriver-7e8b5f43.australiaeast.azurecontainerapps.io`
