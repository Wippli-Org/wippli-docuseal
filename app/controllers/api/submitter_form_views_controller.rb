# frozen_string_literal: true

module Api
  class SubmitterFormViewsController < ApiBaseController
    skip_before_action :authenticate_user!
    skip_authorization_check

    def create
      @submitter = Submitter.find_by!(slug: params[:submitter_slug])

      first_open = @submitter.opened_at.nil?

      @submitter.opened_at = Time.current
      @submitter.save

      SubmissionEvents.create_with_tracking_data(@submitter, 'view_form', request)

      WebhookUrls.enqueue_events(@submitter, 'form.viewed')

      # Wippli: on first open, notify the requester (first submitter) that the
      # counterparty has viewed the document — DocuSign-style. Sent once.
      if first_open
        requester = @submitter.submission.submitters.min_by(&:id)
        if requester && requester.id != @submitter.id && requester.email.present?
          SubmitterMailer.form_viewed_email(@submitter, requester).deliver_later
        end
      end

      render json: {}
    end
  end
end
