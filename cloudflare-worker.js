// Wippli DocuSeal - Strip X-Frame-Options for iframe embedding
// Deploy this to Cloudflare Workers at: https://dash.cloudflare.com

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // Azure Container App origin
  const originHost = 'docuseal-test.whiteforest-41e4af0e.australiaeast.azurecontainerapps.io'

  // Create new URL pointing to Azure Container App
  const url = new URL(request.url)
  url.hostname = originHost

  // Create new request with updated host
  const modifiedRequest = new Request(url, {
    method: request.method,
    headers: request.headers,
    body: request.body,
    redirect: 'follow'
  })

  // Forward request to origin (Azure Container App)
  const response = await fetch(modifiedRequest)

  // Create new response with modified headers
  const newResponse = new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers
  })

  // Remove ALL frame-blocking headers (all case variations)
  newResponse.headers.delete('X-Frame-Options')
  newResponse.headers.delete('x-frame-options')
  newResponse.headers.delete('X-FRAME-OPTIONS')

  // Remove any existing CSP that might block framing
  newResponse.headers.delete('Content-Security-Policy')
  newResponse.headers.delete('content-security-policy')

  // Add our permissive CSP with frame-ancestors for Wippli domains
  const csp = "frame-ancestors 'self' *.wippli.ai app.wippli.ai dev.wippli.ai localhost:* http://localhost:* https://localhost:*"
  newResponse.headers.set('Content-Security-Policy', csp)

  // Add diagnostic header to confirm Cloudflare Worker is active
  newResponse.headers.set('X-Wippli-Cloudflare', 'active')

  // Prevent caching of error responses
  if (newResponse.status >= 400) {
    newResponse.headers.set('Cache-Control', 'no-cache, no-store, must-revalidate')
  }

  return newResponse
}
