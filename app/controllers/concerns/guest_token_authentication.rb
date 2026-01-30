# frozen_string_literal: true

# Guest Token Authentication Concern
# Provides temporary access to DocuSeal forms/submissions without login
#
# IMPORTANT: Payload field names may change in future versions
# Current supported parameters:
#   - guest_token (primary)
#   - guestToken (backward compatibility)
#   - access_token (alternative)
#
# Token Source: Wippli Creator Node payload
# Example tokens:
#   - a60067b5905c9587588a71977d4aa9f4ab7d96f5c6a47c4a7e9222e7171105ce (Brannium)
#   - 77245ec9d371ed69294c85d64f2dedfcef466da101d4d1adfcdf3fe07be45e03 (ProLogistik)
#
module GuestTokenAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_with_guest_token, if: :guest_token_present?
  end

  private

  # Check if a guest token is present in the request
  # Supports multiple parameter names for flexibility
  def guest_token_present?
    extract_guest_token.present?
  end

  # Extract guest token from request parameters
  # NOTE: Field names may change - update this method when payload structure changes
  def extract_guest_token
    params[:guest_token] ||
    params[:guestToken] ||
    params[:access_token] ||
    params[:temp_token]
  end

  # Authenticate user with guest token
  def authenticate_with_guest_token
    token = extract_guest_token

    return unless token

    # Validate token and get associated data
    token_data = validate_guest_token(token)

    if token_data
      # Store token data in session for later use
      session[:guest_token] = token
      session[:guest_token_data] = token_data
      session[:guest_authenticated] = true

      # Log guest token usage for analytics
      log_guest_token_usage(token, token_data)
    else
      # Invalid token - clear session and continue to normal auth
      clear_guest_session
    end
  end

  # Validate guest token
  # TODO: Implement one of these validation strategies:
  #   1. Database lookup (recommended for production)
  #   2. API validation against Wippli Creator Node
  #   3. JWT signature validation
  def validate_guest_token(token)
    case ENV.fetch('GUEST_TOKEN_VALIDATION', 'simple')
    when 'database'
      validate_token_database(token)
    when 'api'
      validate_token_api(token)
    when 'jwt'
      validate_token_jwt(token)
    else
      # Simple validation for development/testing
      # In production, this should be replaced with proper validation
      validate_token_simple(token)
    end
  end

  # Simple token validation (development only)
  # Accepts any 64-character hex string
  def validate_token_simple(token)
    return nil unless token.match?(/\A[a-f0-9]{64}\z/)

    # Return basic token data
    {
      token: token,
      validated_at: Time.current,
      validation_method: 'simple'
    }
  end

  # Database validation (production recommended)
  def validate_token_database(token)
    # TODO: Implement when guest_tokens table is created
    # guest_token_record = GuestToken.active.find_by(token: token)
    # return nil unless guest_token_record&.valid_token?
    #
    # {
    #   token: token,
    #   product_id: guest_token_record.product_id,
    #   company_id: guest_token_record.company_id,
    #   company_code: guest_token_record.company_code,
    #   expires_at: guest_token_record.expires_at,
    #   metadata: guest_token_record.metadata
    # }

    # Fallback to simple validation until DB table exists
    validate_token_simple(token)
  end

  # API validation against Wippli Creator Node
  def validate_token_api(token)
    # TODO: Implement API call to Creator Node
    # response = HTTP.get("#{ENV['WIPPLI_CREATOR_API_URL']}/api/validate-token", params: { token: token })
    # return nil unless response.status.success?
    #
    # JSON.parse(response.body)

    # Fallback to simple validation until API endpoint exists
    validate_token_simple(token)
  end

  # JWT validation
  def validate_token_jwt(token)
    # TODO: Implement JWT validation
    # decoded = JWT.decode(token, ENV['GUEST_TOKEN_SECRET'], true, algorithm: 'HS256')
    # decoded[0]

    # Fallback to simple validation until JWT implementation exists
    validate_token_simple(token)
  rescue JWT::DecodeError
    nil
  end

  # Check if current session is authenticated with guest token
  def guest_authenticated?
    session[:guest_authenticated] == true
  end

  # Get guest token data from session
  def guest_token_data
    session[:guest_token_data]
  end

  # Clear guest session data
  def clear_guest_session
    session.delete(:guest_token)
    session.delete(:guest_token_data)
    session.delete(:guest_authenticated)
  end

  # Log guest token usage for analytics
  def log_guest_token_usage(token, token_data)
    Rails.logger.info("[GUEST_TOKEN] Token used: #{token[-8..-1]} (last 8 chars) - IP: #{request.remote_ip}")

    # TODO: Send to analytics service
    # Analytics.track(
    #   event: 'guest_token_used',
    #   properties: {
    #     token_suffix: token[-8..-1],
    #     ip: request.remote_ip,
    #     user_agent: request.user_agent,
    #     validation_method: token_data[:validation_method]
    #   }
    # )
  end

  # Override signed_in? to include guest authentication
  def signed_in?
    super || guest_authenticated?
  end
end
