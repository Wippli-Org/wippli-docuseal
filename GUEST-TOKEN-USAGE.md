# Guest Token Usage Guide

**Last Updated**: 2026-01-30

## Quick Start

### Test URLs

**ProLogistik Token (ending in 5e03):**
```
https://docuseal.wippli.ai/s/{slug}?guest_token=77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03
```

**Brannium Token (ending in 105ce):**
```
https://docuseal.wippli.ai/s/{slug}?guest_token=a60067b5905c9587588a71977d4aa9f4ab7d96f5c6a47c4a7e9222e7171105ce
```

Replace `{slug}` with actual DocuSeal submission slug.

## Implementation Status

✅ **Completed:**
- Guest token authentication concern created
- Start form controller updated
- Submit form controller updated
- Documentation created

⏳ **Pending:**
- Database table creation (optional - using simple validation for now)
- API validation endpoint (optional)
- JWT validation (optional)
- Analytics integration
- Rate limiting

## How It Works

### 1. User Flow

```
User → n8n Workflow → Creator Node → DocuSeal API
                           ↓
                    Extract guestToken
                           ↓
                 Form URL with token
                           ↓
        User clicks URL with guest_token parameter
                           ↓
              DocuSeal validates token
                           ↓
            Access granted without login
```

### 2. Token Validation Modes

Set via environment variable: `GUEST_TOKEN_VALIDATION`

#### Simple Mode (Default - Development)
```bash
GUEST_TOKEN_VALIDATION=simple
```
- Validates token format (64-char hex string)
- No database or API calls
- Good for testing

#### Database Mode (Production Recommended)
```bash
GUEST_TOKEN_VALIDATION=database
```
- Validates against `guest_tokens` table
- Supports expiration and revocation
- Requires migration (see below)

#### API Mode
```bash
GUEST_TOKEN_VALIDATION=api
WIPPLI_CREATOR_API_URL=https://wippli-creator-toolkit.lemonriver-7e8b5f43.australiaeast.azurecontainerapps.io
```
- Validates via Creator Node API
- Real-time validation
- No local storage

#### JWT Mode
```bash
GUEST_TOKEN_VALIDATION=jwt
GUEST_TOKEN_SECRET=your-secret-key
```
- Self-contained validation
- Signature verification
- Expiration in token

## Parameter Names (Flexible)

**⚠️ NOTE**: Payload field names may change. Current implementation supports:

| Priority | Parameter Name | Source | Status |
|----------|---------------|--------|--------|
| 1 | `guest_token` | Standard | ✅ Primary |
| 2 | `guestToken` | Wippli payload | ✅ Supported |
| 3 | `access_token` | Alternative | ✅ Supported |
| 4 | `temp_token` | Alternative | ✅ Supported |

**All of these work:**
```
?guest_token=77245...5e03
?guestToken=77245...5e03
?access_token=77245...5e03
?temp_token=77245...5e03
```

## Database Migration (Optional)

If using `GUEST_TOKEN_VALIDATION=database`, run this migration:

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_guest_tokens.rb
class CreateGuestTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :guest_tokens do |t|
      t.string :token, null: false, limit: 64
      t.string :token_type, default: 'wippli_product'
      t.integer :product_id
      t.integer :company_id
      t.string :company_code, limit: 20
      t.bigint :epoch
      t.datetime :expires_at
      t.boolean :revoked, default: false
      t.jsonb :metadata, default: {}
      t.timestamps

      t.index :token, unique: true
      t.index :expires_at
      t.index [:product_id, :company_id]
      t.index :revoked
    end
  end
end
```

**Run migration:**
```bash
rails db:migrate
```

## Model (Optional)

```ruby
# app/models/guest_token.rb
class GuestToken < ApplicationRecord
  validates :token, presence: true, uniqueness: true, length: { is: 64 }
  validates :token, format: { with: /\A[a-f0-9]{64}\z/ }

  scope :active, -> { where(revoked: false).where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }

  # Check if token is valid (not expired, not revoked)
  def valid_token?
    !revoked && (expires_at.nil? || expires_at > Time.current)
  end

  # Revoke token
  def revoke!
    update!(revoked: true)
  end

  # Create from Wippli payload
  def self.create_from_payload(payload)
    create!(
      token: payload['guestToken'] || payload['guest_token'],
      product_id: payload['productId'] || payload['product_id'],
      company_id: payload['companyId'] || payload['company_id'],
      company_code: payload['company_code'],
      epoch: payload['epoch'],
      expires_at: payload['epoch'] ? Time.at(payload['epoch']) + 24.hours : 24.hours.from_now,
      metadata: payload
    )
  end
end
```

## API Integration

### Creating Tokens from n8n

**JavaScript Code Node:**
```javascript
// Extract data from Creator Node
const creatorData = $node["Creator Node"].json;
const guestToken = creatorData.guestToken;
const productId = creatorData.creator_product?.id;
const companyId = creatorData.creator_company?.id;
const companyCode = creatorData.creator_company?.code;
const epoch = creatorData.creator_product?.epoch;

// Create DocuSeal submission
const docusealPayload = {
  template_id: items[0].json.template_id,
  send_email: false,
  recipients: [{
    email: items[0].json.email,
    role: "signer"
  }],
  metadata: {
    guest_token: guestToken,
    product_id: productId,
    company_id: companyId,
    company_code: companyCode,
    epoch: epoch
  }
};

return {
  json: docusealPayload
};
```

**HTTP Request to DocuSeal API:**
```javascript
// After creating submission
const submission = $node["Create DocuSeal Submission"].json;
const slug = submission.slug;

// Form the guest access URL
const accessUrl = `https://docuseal.wippli.ai/s/${slug}?guest_token=${guestToken}`;

return {
  json: {
    submission_id: submission.id,
    slug: slug,
    access_url: accessUrl,
    guest_token: guestToken,
    expires_at: new Date(epoch * 1000 + 24*60*60*1000).toISOString() // epoch + 24hrs
  }
};
```

## Testing

### 1. Test with cURL

```bash
# Get submission slug first
SLUG="your-submission-slug"
TOKEN="77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03"

# Test start form
curl -I "https://docuseal.wippli.ai/d/${SLUG}?guest_token=${TOKEN}"

# Test submit form
curl -I "https://docuseal.wippli.ai/s/${SLUG}?guest_token=${TOKEN}"
```

### 2. Check Logs

```bash
# Check for guest token usage
tail -f log/production.log | grep GUEST_TOKEN
```

Expected output:
```
[GUEST_TOKEN] Token used: ...5e03 (last 8 chars) - IP: 20.191.250.254
```

### 3. Test Validation Methods

```bash
# Simple validation (default)
GUEST_TOKEN_VALIDATION=simple rails s

# Database validation
GUEST_TOKEN_VALIDATION=database rails s

# API validation
GUEST_TOKEN_VALIDATION=api \
WIPPLI_CREATOR_API_URL=https://wippli-creator-toolkit.lemonriver-7e8b5f43.australiaeast.azurecontainerapps.io \
rails s
```

## Troubleshooting

### Token Not Working

1. **Check token format**: Must be 64-character hex string
   ```ruby
   # In rails console
   token = "77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03"
   token.match?(/\A[a-f0-9]{64}\z/) # Should be true
   ```

2. **Check session**: Look for guest_authenticated flag
   ```ruby
   # In rails console or logs
   session[:guest_authenticated] # Should be true
   ```

3. **Check validation mode**:
   ```bash
   echo $GUEST_TOKEN_VALIDATION
   ```

4. **Check logs**:
   ```bash
   tail -f log/production.log | grep -E "GUEST_TOKEN|guest_token"
   ```

### Database Validation Not Working

1. **Check table exists**:
   ```bash
   rails db:migrate:status | grep guest_tokens
   ```

2. **Check token record**:
   ```ruby
   GuestToken.find_by(token: "77245...5e03")
   ```

3. **Create test token**:
   ```ruby
   GuestToken.create!(
     token: "77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03",
     product_id: 53,
     company_id: 18,
     expires_at: 1.day.from_now
   )
   ```

## Security Notes

1. **HTTPS Only**: Guest tokens should only work over HTTPS in production
2. **Token Logging**: Only log last 8 characters for security
3. **Session Storage**: Token data stored in encrypted session
4. **Expiration**: All tokens should have expiration dates
5. **Revocation**: Support revoking compromised tokens

## Monitoring

### Key Metrics

```ruby
# Guest token usage (last 24hrs)
# Add to monitoring dashboard

# Total guest sessions
Rails.cache.read('guest_token_sessions_24h')

# Failed validations
Rails.cache.read('guest_token_failures_24h')

# Most used tokens (anonymized)
Rails.cache.read('guest_token_popular')
```

## Payload Field Name Changes

### When Payload Structure Changes

1. Update `extract_guest_token` method in `app/controllers/concerns/guest_token_authentication.rb`
2. Add new parameter name to support list
3. Keep old names for backward compatibility
4. Update documentation
5. Add deprecation warnings if removing old names

### Example Update

```ruby
# If payload changes from 'guestToken' to 'secure_token'
def extract_guest_token
  params[:guest_token] ||      # Standard
  params[:secure_token] ||     # NEW
  params[:guestToken] ||       # Old (backward compatible)
  params[:access_token]
end
```

## Support

For questions or issues:
- Check logs: `log/production.log`
- Review implementation: `GUEST-TOKEN-IMPLEMENTATION.md`
- Test tokens: See "Test URLs" section above
