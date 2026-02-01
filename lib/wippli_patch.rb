# frozen_string_literal: true

# WIPPLI: Aggressive response patching to remove X-Frame-Options
# This patches both Rack::Response and ActionDispatch::Response to ensure
# our headers are always modified, regardless of middleware load order

puts '[WIPPLI] Loading iframe embedding patch...'

module WippliHeaderPatch
  def finish(...)
    status, headers, body = super

    begin
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
      headers['X-Wippli-Patch'] = 'v2-active'
    rescue => e
      warn "[WIPPLI] ERROR in header modification: #{e.class}: #{e.message}"
    end

    [status, headers, body]
  end
end

# Try to patch both Rack::Response and ActionDispatch::Response
patched = []

if defined?(Rack::Response)
  Rack::Response.prepend(WippliHeaderPatch)
  patched << 'Rack::Response'
  puts '[WIPPLI] ✓ Rack::Response patched'
else
  warn '[WIPPLI] ✗ Rack::Response not found'
end

# Patch ActionDispatch::Response if available (after Rails initialization)
if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
  Rails.application.config.after_initialize do
    if defined?(ActionDispatch::Response)
      ActionDispatch::Response.prepend(WippliHeaderPatch)
      patched << 'ActionDispatch::Response'
      puts '[WIPPLI] ✓ ActionDispatch::Response patched'
    else
      warn '[WIPPLI] ✗ ActionDispatch::Response not found'
    end

    if patched.any?
      puts "[WIPPLI] SUCCESS: Patched #{patched.join(', ')} for iframe embedding"
    else
      warn '[WIPPLI] FAILURE: No response classes were patched!'
    end
  end
  puts '[WIPPLI] Patch module loaded, Rails initializer registered...'
else
  # Rails not fully loaded yet, ActionDispatch::Response patch will be skipped
  puts '[WIPPLI] Patch module loaded (Rails application not ready, using Rack::Response only)...'
  if patched.any?
    puts "[WIPPLI] Patched #{patched.join(', ')} for iframe embedding"
  end
end
