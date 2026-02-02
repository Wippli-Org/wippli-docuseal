# frozen_string_literal: true

# Wippli: Handle CORS preflight (OPTIONS) requests for API endpoints.
# Required because Cloudflare proxy (docuseal.wippli.ai) causes cross-origin
# requests from the Wippli app (app.wippli.ai).
class CorsPreflightMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['REQUEST_METHOD'] == 'OPTIONS' && env['PATH_INFO'].start_with?('/api/')
      [204, cors_headers, []]
    else
      @app.call(env)
    end
  end

  private

  def cors_headers
    {
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers' => 'X-Auth-Token, Content-Type, Authorization',
      'Access-Control-Max-Age' => '86400'
    }
  end
end
