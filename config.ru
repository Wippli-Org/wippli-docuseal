# frozen_string_literal: true

puts '[WIPPLI config.ru] Starting DocuSeal with iframe embedding patch...'

# WIPPLI: Load Rails environment first, then apply patch
require_relative 'config/environment'
require_relative 'lib/wippli_patch'

# WIPPLI: Rack middleware to strip X-Frame-Options header (backup layer)
puts '[WIPPLI config.ru] Adding Rack middleware backup layer...'
use(Class.new do
  def initialize(app)
    @app = app
    puts '[WIPPLI Middleware] Initialized'
  end

  def call(env)
    status, headers, body = @app.call(env)

    puts "[WIPPLI Middleware] Processing response, headers before: #{headers.keys.join(', ')}"

    # Remove all variations of X-Frame-Options
    headers.delete_if { |k, _| k.to_s.downcase == 'x-frame-options' }

    # Override CSP with frame-ancestors
    csp = headers['Content-Security-Policy'] || headers['content-security-policy'] || ''
    if csp.empty? || !csp.include?('frame-ancestors')
      headers['Content-Security-Policy'] = "frame-ancestors 'self' *.wippli.ai app.wippli.ai dev.wippli.ai localhost:*; " + csp
    end

    # Proof header
    headers['X-Wippli-Middleware'] = 'v3-active'

    puts "[WIPPLI Middleware] Headers after: #{headers.keys.join(', ')}"

    [status, headers, body]
  end
end)

puts '[WIPPLI config.ru] Running Rails application...'
run Rails.application
Rails.application.load_server
