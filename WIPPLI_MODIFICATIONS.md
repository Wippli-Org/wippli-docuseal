# Wippli Modifications to DocuSeal

This document tracks all modifications made by Wippli to the DocuSeal open-source codebase, as required by the AGPL-3.0 license.

## License Compliance

This is a modified version of DocuSeal (https://github.com/docusealco/docuseal), licensed under AGPL-3.0.

As required by AGPL-3.0 Section 13, we provide:
- Complete source code access via: https://github.com/Wippli-Org/wippli-docuseal
- This documentation of all modifications
- Access to the modified application at: https://docuseal-test.whiteforest-41e4af0e.australiaeast.azurecontainerapps.io

## Modifications

### 1. Template Creation API (2026-02-01)

**Purpose**: Enable PDF template creation via API for automated document workflows.

**Files Modified**:

#### `app/controllers/errors_controller.rb`
- **Lines 14-15**: Commented out `/templates/pdf` and `/api/templates/pdf` from `ENTERPRISE_PATHS`
- **Reason**: Remove Pro Edition restriction to enable open-source template creation API
- **Change**:
  ```ruby
  # Before:
  '/templates/pdf',
  '/api/templates/pdf',

  # After:
  # '/templates/pdf',        # Enabled for Wippli
  # '/api/templates/pdf',    # Enabled for Wippli
  ```

#### `app/controllers/api/templates_pdf_controller.rb`
- **Status**: NEW FILE
- **Purpose**: API controller for creating templates from PDF files
- **Functionality**:
  - Accepts JSON requests with `documents` array
  - Supports PDF files via URL or base64 encoding
  - Uses API token authentication (X-Auth-Token header)
  - Returns JSON response with created template details
  - Reuses existing DocuSeal template creation logic

#### `config/routes.rb`
- **Line 44**: Added route for PDF template creation API
- **Change**:
  ```ruby
  # Wippli: Enable template creation from PDF via API
  resource :templates_pdf, only: %i[create], path: 'templates/pdf', controller: 'templates_pdf'
  ```

### 2. Guest Token Authentication (Previous Modifications)

**Files Modified**:
- `app/controllers/submit_form_controller.rb`: Added guest token validation
- `config.ru`: Added CORS and iframe embedding headers

See commit history for details: https://github.com/Wippli-Org/wippli-docuseal/commits/master

## API Usage

### POST /api/templates/pdf

Create a new template from a PDF file.

**Headers**:
```
X-Auth-Token: your_api_token
Content-Type: application/json
```

**Request Body**:
```json
{
  "name": "Template Name",
  "documents": [
    {
      "name": "document.pdf",
      "file": "https://example.com/document.pdf"
    }
  ]
}
```

Or with base64:
```json
{
  "name": "Template Name",
  "documents": [
    {
      "name": "document.pdf",
      "file": "data:application/pdf;base64,JVBERi0xLjQK..."
    }
  ]
}
```

## Upstream Compatibility

These modifications are designed to:
1. Minimize conflicts with upstream DocuSeal updates
2. Clearly mark Wippli-specific changes with comments
3. Use standard DocuSeal patterns and services

To merge upstream changes:
```bash
git remote add upstream https://github.com/docusealco/docuseal.git
git fetch upstream
git merge upstream/master
# Resolve conflicts in modified files
```

## Support

For questions about these modifications:
- Repository: https://github.com/Wippli-Org/wippli-docuseal
- Contact: dev@wippli.ai

---

*Last Updated: 2026-02-01*
*DocuSeal Base Version: 2.3.1*
*Wippli Version: 2.3.1-wippli*
