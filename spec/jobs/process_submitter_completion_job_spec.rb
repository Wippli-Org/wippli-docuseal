# frozen_string_literal: true

RSpec.describe ProcessSubmitterCompletionJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
  let(:submission) { create(:submission, template:, created_by_user: user) }
  let(:submitter) { create(:submitter, submission:, uuid: SecureRandom.uuid, completed_at: Time.current) }

  before do
    create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                              value: GenerateCertificate.call.transform_values(&:to_pem))
  end

  describe '#perform' do
    it 'creates a completed submitter' do
      expect do
        described_class.new.perform('submitter_id' => submitter.id)
      end.to change(CompletedSubmitter, :count).by(1)

      completed_submitter = CompletedSubmitter.last
      submitter.reload

      expect(completed_submitter.submitter_id).to eq(submitter.id)
      expect(completed_submitter.submission_id).to eq(submitter.submission_id)
      expect(completed_submitter.account_id).to eq(submitter.submission.account_id)
      expect(completed_submitter.template_id).to eq(submitter.submission.template_id)
      expect(completed_submitter.source).to eq(submitter.submission.source)
    end

    it 'creates a completed document' do
      expect do
        described_class.new.perform('submitter_id' => submitter.id)
      end.to change(CompletedDocument, :count).by(1)

      completed_document = CompletedDocument.last

      expect(completed_document.submitter_id).to eq(submitter.id)
      expect(completed_document.sha256).to be_present
      expect(completed_document.sha256).to eq(submitter.documents.first.metadata['sha256'])
    end

    it 'raises an error if the submitter is not found' do
      expect do
        described_class.new.perform('submitter_id' => 'invalid_id')
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#maybe_enqueue_copy_emails' do
    let(:template) { create(:template, account:, author: user, submitter_count: 3) }
    let(:submission) { create(:submission, :with_submitters, template:, created_by_user: user) }

    it 'sends every party their own copy, each built on the last signer' do
      parties = submission.submitters.order(:id).to_a
      parties.each_with_index { |party, i| party.update!(completed_at: (3 - i).minutes.ago) }
      last_signer = parties.max_by(&:completed_at)
      delivery = instance_double(ActionMailer::MessageDelivery, deliver_later!: true)

      allow(SubmitterMailer).to receive(:documents_copy_email).and_return(delivery)

      described_class.new.send(:maybe_enqueue_copy_emails, last_signer)

      expect(SubmitterMailer).to have_received(:documents_copy_email).exactly(3).times
      parties.each do |party|
        expect(SubmitterMailer).to have_received(:documents_copy_email).with(last_signer, recipient: party)
      end
    end

    it 'skips a party whose emails are turned off' do
      parties = submission.submitters.order(:id).to_a
      parties.each { |party| party.update!(completed_at: Time.current) }
      parties.first.update!(preferences: { 'send_email' => false })
      delivery = instance_double(ActionMailer::MessageDelivery, deliver_later!: true)

      allow(SubmitterMailer).to receive(:documents_copy_email).and_return(delivery)

      described_class.new.send(:maybe_enqueue_copy_emails, parties.last)

      expect(SubmitterMailer).to have_received(:documents_copy_email).twice
      expect(SubmitterMailer).not_to have_received(:documents_copy_email).with(anything, recipient: parties.first)
    end
  end
end
