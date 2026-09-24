# frozen_string_literal: true

RSpec.describe SubmitterMailer do
  describe '#documents_copy_email' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account:) }
    let(:template) { create(:template, account:, author: user, submitter_count: 2) }
    let(:submission) { create(:submission, :with_submitters, template:, created_by_user: user) }
    let(:first_signer) { submission.submitters.order(:id).first }
    let(:last_signer) { submission.submitters.order(:id).last }

    def html_of(mail)
      (mail.html_part || mail).body.decoded
    end

    before do
      create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                                value: GenerateCertificate.call.transform_values(&:to_pem))
      first_signer.update!(name: 'Alice Tenant', completed_at: 2.minutes.ago)
      last_signer.update!(name: 'Bruno Landlord', completed_at: 1.minute.ago)
    end

    it 'is addressed to and greets the recipient, with the last signer as the source of the documents' do
      allow(Submissions::EnsureResultGenerated).to receive(:call).and_call_original

      mail = described_class.documents_copy_email(last_signer, recipient: first_signer)

      expect(mail.to).to eq([first_signer.email])
      expect(html_of(mail)).to include('Hi Alice Tenant,')
      expect(html_of(mail)).not_to include('Bruno Landlord')
      expect(Submissions::EnsureResultGenerated).to have_received(:call).with(last_signer)
    end

    it 'is addressed to the signer when no recipient is given' do
      mail = described_class.documents_copy_email(last_signer)

      expect(mail.to).to eq([last_signer.email])
      expect(html_of(mail)).to include('Hi Bruno Landlord,')
    end
  end
end
