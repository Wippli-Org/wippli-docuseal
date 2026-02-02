# frozen_string_literal: true

module Api
  class SigningKeyVerificationController < ApiBaseController
    skip_before_action :authenticate_user!
    skip_authorization_check

    def create
      RateLimit.call("verify-signing-key-#{request.remote_ip}", limit: 10, ttl: 1.minute, enabled: true)

      key = params[:key].to_s.strip
      return render json: { error: 'Invalid signing key' }, status: :not_found unless key.match?(/\A\d{6}\z/)

      submitter = Submitter.joins(:submission)
                           .where('submitters.metadata LIKE ?', "%\"signing_key\":\"#{key}\"%")
                           .first

      if submitter
        render json: {
          slug: submitter.slug,
          role: submitter.name,
          status: submitter.completed_at ? 'completed' : 'pending',
          submission_id: submitter.submission_id
        }
      else
        render json: { error: 'Invalid signing key' }, status: :not_found
      end
    end
  end
end
