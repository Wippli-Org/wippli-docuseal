# frozen_string_literal: true

# CRITICAL: Allow iframe embedding from Wippli domains
# Inline middleware to remove X-Frame-Options header

class WippliIframeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    # Test header to prove we're running
    headers['X-Wippli-Fix'] = 'v1'

    # Remove X-Frame-Options (case-insensitive)
    headers.delete_if { |k, _v| k.downcase == 'x-frame-options' }

    # Add CSP with frame-ancestors
    headers['Content-Security-Policy'] = "frame-ancestors 'self' *.wippli.ai app.wippli.ai dev.wippli.ai localhost:*"

    [status, headers, body]
  end
end

Rails.application.config.middleware.use WippliIframeMiddleware
