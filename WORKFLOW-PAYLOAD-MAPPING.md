# Wippli → DocuSeal Workflow Payload Mapping

## Actual Wippli Payload Structure

Based on the payload you showed, here's how the data is structured:

```javascript
{
  // Product Info
  creator_product: {
    id: 72,                    // Product ID
    guestToken: "a60067b...",  // Guest token for DocuSeal URL
    name: "Docu Free"
  },

  // Company Info
  supplier_companyId: 8,        // Brannium (use this for companyId)
  company_id: 5,                // Client company (NOT used for branding)
  supplier_companyName: "Brannium",

  // Wippli Info
  wippli_id: 1001,

  // User Info
  user_email: "guest-8549adb45abe@system.local",
  user_firstName: "Guest",
  user_lastName: "8549adb45abe",

  // Custom Form Fields
  wippli_customFormFields: {
    Document: {
      value: "https://wippli-production.s3...e251208auspa489522977.pdf"  // PDF URL!
    },
    Signatore: {
      value: "Jay Marcano"
    },
    email: {
      value: "admin@wippli.com"
    }
  }
}
```

## Required Workflow Changes

### 1. Get Guest Token Node
**Current (WRONG):**
```javascript
productId: {{ $json.product_id }}
companyId: {{ $json.company_id }}
```

**Correct:**
```javascript
productId: {{ $json.creator_product.id }}        // 72
companyId: {{ $json.supplier_companyId }}        // 8
```

### 2. **NEW NODE REQUIRED: Download PDF**
Insert between "Get Guest Token" and "Upload PDF Template":

```json
{
  "name": "Download PDF",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "GET",
    "url": "={{ $node['Webhook'].json.wippli_customFormFields.Document.value }}",
    "options": {
      "response": {
        "response": {
          "responseFormat": "file"
        }
      }
    }
  }
}
```

### 3. Upload PDF Template Node
**Current (WRONG):**
```javascript
files[]: {{ $json.pdf_base64 }}
name: {{ $json.document_name }}
```

**Correct:**
```javascript
files[]: {{ $binary.data }}  // Binary data from Download PDF node
name: {{ $node['Webhook'].json.wippli_customFormFields.Signatore.value + ' - Document' }}
```

### 4. Create Submission Node
**Current (WRONG):**
```javascript
submitters: [{"email": $node["Webhook"].json.user_email, "name": $node["Webhook"].json.user_name}]
metadata: {
  "wippli_id": $node["Webhook"].json.wippli_id,
  "product_id": $node["Webhook"].json.product_id,
  "company_id": $node["Webhook"].json.company_id
}
```

**Correct:**
```javascript
submitters: [{
  "email": $node["Webhook"].json.wippli_customFormFields.email.value,
  "name": $node["Webhook"].json.wippli_customFormFields.Signatore.value
}]
metadata: {
  "wippli_id": $node["Webhook"].json.wippli_id,
  "product_id": $node["Webhook"].json.creator_product.id,
  "company_id": $node["Webhook"].json.supplier_companyId,
  "user_email": $node["Webhook"].json.user_email
}
```

### 5. Format Response Node
**Current (WRONG):**
```javascript
const guestToken = creatorData.creator_product?.guestToken || creatorData.guestToken;
const webhookData.product_id;
```

**Correct:**
```javascript
const guestToken = webhookData.creator_product.guestToken;
product_id: webhookData.creator_product.id,
company_id: webhookData.supplier_companyId
```

## Critical Issue: PDF Download

The biggest issue is that Wippli sends a **PDF URL**, not base64 data. You have two options:

### Option A: Add Download PDF Node (Recommended)
1. Insert a new HTTP Request node that downloads the PDF from the URL
2. Set response format to "file" to get binary data
3. Update Upload PDF Template to use `$binary.data`

### Option B: Modify Wippli to Send Base64
Have Wippli download the PDF and include it as base64 in the payload:
```json
{
  "pdf_base64": "JVBERi0xLjQK...",
  "document_name": "Jay Marcano - Document",
  // ... rest of payload
}
```

## Test Payload

For testing in n8n directly, you can use this simplified version:

```json
{
  "creator_product": {
    "id": 72,
    "guestToken": "a60067b5905c9587588a71977d4aa9f4ab7d96f5c6a47c4a7e9222e7171105ce"
  },
  "supplier_companyId": 8,
  "wippli_id": 1001,
  "user_email": "test@wippli.ai",
  "user_firstName": "Test",
  "user_lastName": "User",
  "wippli_customFormFields": {
    "Document": {
      "value": "https://wippli-production.s3.ap-southeast-2.amazonaws.com/wippli/uploads/4debbfaa-74db-18d9-aae8-6e05643548ab/e251208auspa489522977.pdf"
    },
    "Signatore": {
      "value": "Test User"
    },
    "email": {
      "value": "test@wippli.ai"
    }
  }
}
```

## Next Steps

1. Open n8n UI at https://n8n-playground.wippli.ai/
2. Delete the existing "WippliSign with Field Detection" workflow
3. Create a new workflow with these corrected node configurations
4. **Add the "Download PDF" node** between "Get Guest Token" and "Upload PDF Template"
5. Test with the actual Wippli payload structure

The workflow file I've been updating is close, but needs the Download PDF node added manually in the UI since it requires restructuring the node connections.
