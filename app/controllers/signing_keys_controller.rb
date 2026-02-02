# frozen_string_literal: true

# Wippli: Controller to resolve 6-digit signing keys to signing forms
class SigningKeysController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :maybe_redirect_to_setup
  layout false

  def show
    if params[:key].present?
      submitter = Submitter.where("CAST(metadata AS jsonb)->>'signing_key' = ?", params[:key].strip).first

      if submitter
        redirect_to submit_form_path(slug: submitter.slug), allow_other_host: true
      else
        @error = 'Invalid signing key. Please check and try again.'
        render :new
      end
    else
      render :new
    end
  end

  def new; end
end
