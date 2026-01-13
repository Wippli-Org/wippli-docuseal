# frozen_string_literal: true

require_relative 'config/environment'

# WIPPLI: Rack middleware to strip X-Frame-Options header
use(Class.new do
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    # Remove all variations of X-Frame-Options
    headers.delete_if { |k, _| k.to_s.downcase == 'x-frame-options' }

    # Override CSP with frame-ancestors
    csp = headers['Content-Security-Policy'] || headers['content-security-policy'] || ''
    if csp.empty? || !csp.include?('frame-ancestors')
      headers['Content-Security-Policy'] = "frame-ancestors 'self' *.wippli.ai app.wippli.ai dev.wippli.ai localhost:*; " + csp
    end

    # Proof header
    headers['X-Wippli-Rack-v2'] = 'active'

    [status, headers, body]
  end
end)

run Rails.application
Rails.application.load_server
