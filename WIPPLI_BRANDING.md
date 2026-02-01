# Wippli Branding Customization

This document describes the branding customization features added to DocuSeal for Wippli.

## Overview

Enable account-level branding customization including custom logo, application name, and primary color through the admin UI.

## Features

1. **Custom Logo**: Upload/specify logo URL to replace default DocuSeal logo
2. **Application Name**: Customize the app name shown in the interface
3. **Primary Color**: Set brand's primary color for buttons and accents

## Implementation

### 1. Database Configuration

**File**: `app/models/account_config.rb`

Added three new configuration keys:
```ruby
BRAND_LOGO_URL_KEY = 'brand_logo_url'
BRAND_APP_NAME_KEY = 'brand_app_name'
BRAND_PRIMARY_COLOR_KEY = 'brand_primary_color'
```

These are stored in the existing `account_configs` table as key-value pairs.

### 2. Controller Updates

**File**: `app/controllers/personalization_settings_controller.rb`

Added branding keys to `ALLOWED_KEYS` array:
```ruby
AccountConfig::BRAND_LOGO_URL_KEY,
AccountConfig::BRAND_APP_NAME_KEY,
AccountConfig::BRAND_PRIMARY_COLOR_KEY
```

**File**: `app/controllers/templates_controller.rb`

Load branding configuration in the `edit` action:
```ruby
# Wippli: Load branding configuration for template editor
if user_signed_in?
  account = current_account
  @brand_logo_url = account.account_configs.find_by(key: AccountConfig::BRAND_LOGO_URL_KEY)&.value
  @brand_app_name = account.account_configs.find_by(key: AccountConfig::BRAND_APP_NAME_KEY)&.value
  @brand_primary_color = account.account_configs.find_by(key: AccountConfig::BRAND_PRIMARY_COLOR_KEY)&.value
end
```

### 3. Vue Component Updates

**File**: `app/javascript/template_builder/logo.vue`

Modified to accept dynamic logo and app name as props:
```vue
<template>
  <!-- Support custom logo URL from branding config -->
  <img
    v-if="logoUrl"
    :src="logoUrl"
    :alt="appName || 'Logo'"
    height="40"
    class="max-w-none"
  >
  <svg v-else ...>
    <!-- Default DocuSeal logo SVG -->
  </svg>
</template>

<script>
export default {
  name: 'ProjectLogo',
  props: {
    logoUrl: {
      type: String,
      required: false,
      default: ''
    },
    appName: {
      type: String,
      required: false,
      default: ''
    }
  }
}
</script>
```

### 4. Admin UI

**File**: `app/views/personalization_settings/_branding_form.html.erb` (NEW)

Created comprehensive branding configuration UI with three sections:

1. **Logo URL Form**: Text input for logo image URL
2. **Application Name Form**: Text input for custom app name
3. **Primary Color Form**: Color picker + hex input for brand color

**File**: `app/views/personalization_settings/show.html.erb`

Updated to render `branding_form` instead of `logo_form`:
```erb
<%# Wippli: Use branding form instead of simple logo form %>
<%= render 'branding_form' %>
```

## Usage

### For Administrators

1. Navigate to **Settings** → **Personalization**
2. Scroll to **Company Logo** section
3. Configure branding options:
   - **Logo URL**: Enter the URL to your logo (SVG, PNG, or JPG)
   - **Application Name**: Enter your company name
   - **Primary Color**: Pick your brand color (hex format)
4. Click **Update** for each field

### For Developers

To pass branding to the template editor:

```erb
<template-builder
  :logo-url="<%= @brand_logo_url.to_json %>"
  :app-name="<%= @brand_app_name.to_json %>"
  :primary-color="<%= @brand_primary_color.to_json %>"
  ...
></template-builder>
```

## Files Modified

1. `app/models/account_config.rb` - Added branding config keys
2. `app/controllers/personalization_settings_controller.rb` - Added keys to allowed list
3. `app/controllers/templates_controller.rb` - Load branding config in edit action
4. `app/javascript/template_builder/logo.vue` - Accept dynamic logo props
5. `app/views/personalization_settings/_branding_form.html.erb` - NEW: Branding UI
6. `app/views/personalization_settings/show.html.erb` - Use branding form

## Benefits

- **No Docker Rebuild**: Changes are database-driven, no need to rebuild images
- **Account-Level**: Each account can have its own branding
- **Easy to Use**: Simple admin UI for non-technical users
- **Backward Compatible**: Falls back to default DocuSeal branding if not configured

## Future Enhancements

Potential improvements:
- File upload for logo (Active Storage integration)
- Multiple color customization (secondary, accent colors)
- Custom CSS injection for advanced theming
- Favicon customization
- Email template branding

---

*Created: 2026-02-01*
*Branch: wippli-branding*
*Base Version: 2.3.1*
