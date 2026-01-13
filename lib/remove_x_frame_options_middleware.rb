# frozen_string_literal: true

# Middleware to remove X-Frame-Options header and add Content-Security-Policy for Wippli iframe embedding
class RemoveXFrameOptionsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    # Add test header to prove middleware is running
    headers['X-Wippli-Iframe-Fix'] = 'active'

    # Remove X-Frame-Options with all possible case variations
    headers.delete_if { |k, _v| k.downcase == 'x-frame-options' }

    # Add Content-Security-Policy with frame-ancestors for Wippli domains
    headers['Content-Security-Policy'] = "frame-ancestors 'self' *.wippli.ai app.wippli.ai dev.wippli.ai localhost:*"

    [status, headers, body]
  end
end
