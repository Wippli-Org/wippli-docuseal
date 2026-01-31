# frozen_string_literal: true

module GuestTokenAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :check_guest_token
  end

  private

  def check_guest_token
    token = params[:guest_token] || params[:guestToken]

    return unless token.present?

    # Validate token format: 64-character hexadecimal string
    if valid_guest_token?(token)
      # Mark session as guest authenticated
      session[:guest_token] = token
      session[:guest_authenticated] = true

      Rails.logger.info "Guest token authenticated: #{token[0..7]}..." if Rails.env.development?
    end
  end

  def valid_guest_token?(token)
    # Token must be exactly 64 characters and hexadecimal
    token.is_a?(String) && token.length == 64 && token.match?(/\A[0-9a-f]{64}\z/i)
  end

  def guest_authenticated?
    session[:guest_authenticated] == true
  end
end
