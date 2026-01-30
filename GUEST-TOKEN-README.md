# Guest Token Implementation - Summary

**Date**: 2026-01-30
**Status**: ✅ Implemented (Basic validation)

## What Was Done

### 1. Created Guest Token Authentication System
- **File**: `app/controllers/concerns/guest_token_authentication.rb`
- Provides temporary access without login
- Supports multiple parameter names (flexible for payload changes)
- Includes logging and session management

### 2. Updated Controllers
- **File**: `app/controllers/start_form_controller.rb` - Added guest token support
- **File**: `app/controllers/submit_form_controller.rb` - Added guest token support

### 3. Documentation Created
- **GUEST-TOKEN-IMPLEMENTATION.md** - Technical implementation details
- **GUEST-TOKEN-USAGE.md** - Usage guide and testing
- **GUEST-TOKEN-README.md** - This summary

## Quick Test

### Test URLs (Use actual submission slug)

**ProLogistik Token:**
```
https://docuseal.wippli.ai/s/{slug}?guest_token=77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03
```

**Brannium Token:**
```
https://docuseal.wippli.ai/s/{slug}?guest_token=a60067b5905c9587588a71977d4aa9f4ab7d96f5c6a47c4a7e9222e7171105ce
```

## Current Implementation

### Validation Mode: SIMPLE (Default)
- ✅ Accepts any 64-character hex token
- ✅ No database required
- ✅ Good for testing/development
- ⚠️ For production, switch to `database` or `api` mode

### Supported Parameter Names
All of these work (flexible for payload changes):
- `?guest_token=...` (primary)
- `?guestToken=...` (Wippli payload format)
- `?access_token=...` (alternative)
- `?temp_token=...` (alternative)

## ⚠️ IMPORTANT NOTES

### Payload Field Names May Change
The current implementation supports multiple parameter names to handle future payload changes:

**Current payload structure:**
```json
{
  "guestToken": "77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03",
  "resultSecure": "https://app.wippli.ai/product/53-1769483473?guest_token=...",
  "productId": 53,
  "companyId": 18,
  "epoch": 1769483473
}
```

**If field names change**, update this method:
```ruby
# app/controllers/concerns/guest_token_authentication.rb
def extract_guest_token
  params[:guest_token] ||
  params[:guestToken] ||      # Current Wippli format
  params[:secure_token] ||    # Add new names here
  params[:access_token]
end
```

## How Users Access DocuSeal

### Before (Required Login)
1. User visits DocuSeal URL
2. Sees login page ❌
3. Must create account/login

### After (With Guest Token)
1. User visits URL with `?guest_token=...`
2. **Automatically authenticated** ✅
3. Can fill/sign document immediately
4. No login required

## Token Data

### ProLogistik Token (ending in 5e03)
```
Token: 77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03
Product: 53 (ProLo Chat)
Company: 18 (proLogistik)
Company Code: 9d20b11edb814f4efbb8
```

### Brannium Token (ending in 105ce)
```
Token: a60067b5905c9587588a71977d4aa9f4ab7d96f5c6a47c4a7e9222e7171105ce
Product: 72 (Docu Free)
Company: 8 (Brannium)
```

## Next Steps (Optional)

### For Production Use

1. **Enable Database Validation** (Recommended)
   ```bash
   # Create migration
   rails generate migration CreateGuestTokens

   # Set validation mode
   export GUEST_TOKEN_VALIDATION=database
   ```

2. **Add Token Storage**
   - Store tokens when created via n8n workflow
   - Set expiration dates (e.g., 24 hours)
   - Support revocation

3. **Add Analytics**
   - Track guest token usage
   - Monitor conversion rates
   - Log access patterns

4. **Add Rate Limiting**
   - Prevent token abuse
   - Limit requests per token

## Testing

### 1. Check Implementation
```bash
# Start Rails server
rails s

# Check logs for guest token
tail -f log/development.log | grep GUEST_TOKEN
```

### 2. Test Token Access
Visit in browser:
```
http://localhost:3000/s/{slug}?guest_token=77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03
```

Expected:
- ✅ No login page
- ✅ Direct access to form
- ✅ Log entry: `[GUEST_TOKEN] Token used: ...5e03`

### 3. Test Without Token
Visit without token:
```
http://localhost:3000/s/{slug}
```

Expected:
- Normal authentication flow
- May require login (depending on template settings)

## Files Modified

```
app/controllers/concerns/guest_token_authentication.rb       [NEW]
app/controllers/start_form_controller.rb                     [MODIFIED]
app/controllers/submit_form_controller.rb                    [MODIFIED]
GUEST-TOKEN-IMPLEMENTATION.md                                [NEW]
GUEST-TOKEN-USAGE.md                                         [NEW]
GUEST-TOKEN-README.md                                        [NEW]
```

## Configuration

### Environment Variables

```bash
# Validation method (simple, database, api, jwt)
GUEST_TOKEN_VALIDATION=simple

# Creator API URL (for api validation)
WIPPLI_CREATOR_API_URL=https://wippli-creator-toolkit.lemonriver-7e8b5f43.australiaeast.azurecontainerapps.io

# Token TTL (seconds)
GUEST_TOKEN_TTL=86400  # 24 hours
```

## Deployment

### To Deploy These Changes

```bash
# 1. Commit changes
git add .
git commit -m "Add guest token authentication for temporary access

- Created GuestTokenAuthentication concern
- Updated start_form and submit_form controllers
- Supports multiple parameter names (guest_token, guestToken, etc.)
- Simple validation mode for development
- Comprehensive documentation

NOTE: Payload field names may change - implementation is flexible

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# 2. Push to repository
git push origin wippli-iframe-embedding

# 3. Deploy to Azure (if configured)
# Azure should auto-deploy from the branch
```

## Support & Documentation

- **Implementation Details**: `GUEST-TOKEN-IMPLEMENTATION.md`
- **Usage Guide**: `GUEST-TOKEN-USAGE.md`
- **This Summary**: `GUEST-TOKEN-README.md`

## Questions?

1. How do I test this?
   → See "Testing" section above

2. What if payload field names change?
   → Implementation supports multiple names - see "Payload Field Names May Change" section

3. How do I switch to database validation?
   → See `GUEST-TOKEN-USAGE.md` → "Database Migration" section

4. Is this secure?
   → Using simple validation for now. For production, use database or API validation with expiration

5. Can I use different token parameter names?
   → Yes! Supports: guest_token, guestToken, access_token, temp_token
