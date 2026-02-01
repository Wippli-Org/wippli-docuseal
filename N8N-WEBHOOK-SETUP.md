# n8n Webhook Setup - Final Steps

## Current Status

The workflow "WippliSign with Field Detection" has been successfully:
- Created and imported to n8n (ID: `thS7MtHDPVEz7i0Q`)
- Marked as active
- Container restarted

## Issue

The webhook is not registering because n8n requires manual activation through the UI on first import.

## Solution - Complete These Steps

1. **Open n8n**: Go to https://n8n-playground.wippli.ai/

2. **Find the workflow**: Look for "WippliSign with Field Detection" in the workflow list

3. **Activate the workflow**:
   - Open the workflow
   - If the toggle in the top-right shows "Active", toggle it OFF then ON again
   - If it shows "Inactive", toggle it ON
   - Click "Save" if prompted

4. **Verify webhook registration**:
   ```bash
   curl -X POST 'https://n8n-playground.wippli.ai/webhook/wippli-docuseal-ai' \
     -H 'Content-Type: application/json' \
     -d '{
       "pdfBase64": "JVBERi0xLjQKJeLjz9M...",
       "documentName": "Test Document",
       "wippliId": "test-001",
       "nodesObject": {
         "wippli": {"productId": "72", "companyId": "8"},
         "user": {"email": "test@wippli.ai", "firstName": "Test", "lastName": "User"}
       }
     }'
   ```

   Expected: JSON response with `docuseal.url` containing guest token
   Current: 404 "webhook not registered"

## Webhook Details

- **Endpoint**: `POST /webhook/wippli-docuseal-ai`
- **Full URL**: https://n8n-playground.wippli.ai/webhook/wippli-docuseal-ai
- **Test URL**: https://n8n-playground.wippli.ai/webhook-test/wippli-docuseal-ai

## Workflow Steps

1. Webhook receives PDF + metadata
2. Get Guest Token from Creator Toolkit
3. Upload PDF Template to DocuSeal
4. Detect Signature Fields (AI)
5. Create Submission
6. Format Response with guest token URL
7. Return JSON response

## Test Payload Ready

Test payload has been prepared at `/tmp/test-webhook-payload.json` and is ready to send once the webhook is activated in the UI.

## Next Step

**ACTION REQUIRED**: Open n8n UI and toggle the workflow off/on to register the webhook, then run the test curl command above.
