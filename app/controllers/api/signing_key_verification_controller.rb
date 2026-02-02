# frozen_string_literal: true

module Api
  class SigningKeyVerificationController < ApiBaseController
    skip_before_action :authenticate_user!
    skip_authorization_check

    def create
      submitter = Submitter.joins(:submission)
                           .where("submitters.metadata->>'signing_key' = ?", params[:key].to_s.strip)
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
