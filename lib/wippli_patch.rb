# frozen_string_literal: true

# WIPPLI: Aggressive Rack response patching to remove X-Frame-Options
# This patches the Rack::Response class directly to ensure our headers
# are always modified, regardless of middleware load order

module WippliHeaderPatch
  def finish(...)
    status, headers, body = super

    # Remove X-Frame-Options header (all case variations)
    headers.delete('X-Frame-Options')
    headers.delete('x-frame-options')
    headers.delete_if { |k, _| k.to_s.downcase == 'x-frame-options' }

    # Add Content-Security-Policy with frame-ancestors
    csp_base = "frame-ancestors 'self' *.wippli.ai app.wippli.ai dev.wippli.ai localhost:*"
    existing_csp = headers['Content-Security-Policy'] || headers['content-security-policy'] || ''

    if existing_csp.empty? || !existing_csp.include?('frame-ancestors')
      headers['Content-Security-Policy'] = "#{csp_base}; #{existing_csp}".strip
    end

    # Diagnostic header to confirm patch is active
    headers['X-Wippli-Patch'] = 'v1-active'

    [status, headers, body]
  end
end

# Prepend our patch to Rack::Response (executes before original method)
if defined?(Rack::Response)
  Rack::Response.prepend(WippliHeaderPatch)
  puts '[WIPPLI] Rack::Response patched for iframe embedding'
else
  warn '[WIPPLI] WARNING: Rack::Response not found, patch not applied!'
end
