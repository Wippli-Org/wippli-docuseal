# frozen_string_literal: true

module Api
  class TemplatesPdfController < ApiBaseController
    skip_authorization_check only: :create

    before_action only: :create do
      authorize!(:create, Template)
    end

    def create
      template = Template.new

      template.account = current_account
      template.author = current_user
      template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
      template.name = params[:name] || 'Untitled Template'

      Templates.maybe_assign_access(template)

      template.save!

      documents_params = build_documents_params(params[:documents])
      documents = Templates::CreateAttachments.call(template, documents_params, extract_fields: true)

      schema = documents.map { |doc| { attachment_uuid: doc.uuid, name: doc.filename.base } }

      if template.fields.blank?
        template.fields = Templates::ProcessDocument.normalize_attachment_fields(template, documents)
        schema.each { |item| item['pending_fields'] = true } if template.fields.present?
      end

      template.update!(schema:)

      WebhookUrls.enqueue_events(template, 'template.created')
      SearchEntries.enqueue_reindex(template)

      render json: Templates::SerializeForApi.call(template)
    rescue Templates::CreateAttachments::PdfEncrypted => e
      Rollbar.warning(e) if defined?(Rollbar)
      render json: { error: 'PDF is encrypted. Please provide an unencrypted PDF.' }, status: :unprocessable_content
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)
      render json: { error: e.message }, status: :unprocessable_content
    end

    private

    def build_documents_params(documents_array)
      return {} if documents_array.blank?

      files = documents_array.map do |doc|
        file_data = doc[:file] || doc['file']

        # Handle base64 data URLs (e.g., "data:application/pdf;base64,...")
        if file_data.to_s.start_with?('data:')
          create_file_from_base64(file_data, doc[:name] || doc['name'] || 'document.pdf')
        # Handle direct URLs
        elsif file_data.to_s.match?(%r{^https?://})
          create_file_from_url(file_data, doc[:name] || doc['name'])
        # Handle raw base64 (without data: prefix)
        else
          create_file_from_base64("data:application/pdf;base64,#{file_data}", doc[:name] || doc['name'] || 'document.pdf')
        end
      end.compact

      { files: }
    end

    def create_file_from_url(url, filename = nil)
      tempfile = Tempfile.new
      tempfile.binmode
      tempfile.write(DownloadUtils.call(url).body)
      tempfile.rewind

      filename ||= File.basename(URI.decode_www_form_component(url))

      ActionDispatch::Http::UploadedFile.new(
        tempfile:,
        filename:,
        type: Marcel::MimeType.for(tempfile)
      )
    end

    def create_file_from_base64(data_url, filename)
      # Extract base64 content from data URL
      match = data_url.match(%r{^data:([^;]+);base64,(.+)$})
      return nil unless match

      content_type = match[1]
      base64_content = match[2]

      decoded = Base64.decode64(base64_content)

      tempfile = Tempfile.new
      tempfile.binmode
      tempfile.write(decoded)
      tempfile.rewind

      ActionDispatch::Http::UploadedFile.new(
        tempfile:,
        filename:,
        type: content_type
      )
    end
  end
end
