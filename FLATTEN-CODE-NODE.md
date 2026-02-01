# Flatten Creator Data Node

## Node Configuration

**Node Type:** Code (JavaScript)
**Name:** Flatten Creator Data
**Position:** Between "Get Guest Token" and "Upload PDF Template"

## JavaScript Code

```javascript
// Get the creator data from the previous node (it's an array)
const creatorData = $input.first().json;

// Extract the first item if it's an array
const data = Array.isArray(creatorData) ? creatorData[0] : creatorData;

// Also get the webhook data for later reference
const webhookData = $node["Webhook"].json;

// Extract the guest token from the creator data
const guestToken = data.creator_product?.guestToken;

// Extract PDF URL from webhook data
const pdfUrl = webhookData.wippli_customFormFields?.Document?.value;

// Extract signer info
const signerName = webhookData.wippli_customFormFields?.Signatore?.value;
const signerEmail = webhookData.wippli_customFormFields?.email?.value;

// Return flattened data for next nodes
return {
  json: {
    // Creator data
    creator_product: data.creator_product,
    creator_company: data.creator_company,
    guest_token: guestToken,

    // Webhook data we'll need
    pdf_url: pdfUrl,
    signer_name: signerName,
    signer_email: signerEmail,
    wippli_id: webhookData.wippli_id,

    // Branding data (for later use if needed)
    branding: data.creator_company?.branding
  }
};
```

## Updated Workflow Structure

```
1. Webhook (receives Wippli data)
2. Get Guest Token (calls Creator Toolkit API)
3. **NEW: Flatten Creator Data** (extracts and flattens response)
4. Download PDF (fetch PDF from URL)
5. Upload PDF Template (upload to DocuSeal)
6. Detect Signature Fields (AI detection)
7. Create Submission (with signer info)
8. Format Response (add guest token to URL)
9. Respond to Webhook (return JSON)
```

## Connection Updates

**Old:**
```
Get Guest Token → Upload PDF Template
```

**New:**
```
Get Guest Token → Flatten Creator Data → Download PDF → Upload PDF Template
```

## Why This is Needed

The Creator Toolkit API returns:
```json
[{
  "creator_product": { "guestToken": "..." },
  "creator_company": { ... },
  ...
}]
```

This code node:
1. Extracts the first array item
2. Pulls out the guest token
3. Gets the PDF URL from webhook data
4. Returns a flat, easy-to-use structure

## Next Steps in n8n UI

1. Open the "WippliSign with Field Detection" workflow
2. Click between "Get Guest Token" and "Upload PDF Template"
3. Add a new **Code** node
4. Name it "Flatten Creator Data"
5. Paste the JavaScript code above
6. Reconnect the nodes in the new order
7. Save and test

This will fix the workflow to handle the actual Wippli + Creator Toolkit payload structure.
