require "imap/backup/email/provider/base"

module Imap::Backup
  RSpec.describe Email::Provider::Base do
    describe "#options" do
      it "returns options" do
        expect(subject.options).to be_a(Hash)
      end

      it "forces TLSv1_2" do
        # rubocop:disable Naming/VariableNumber
        expect(subject.options[:ssl][:min_version]).to eq(OpenSSL::SSL::TLS1_2_VERSION)
        # rubocop:enable Naming/VariableNumber
      end
    end

    describe "#sets_seen_flags_on_fetch?" do
      it "is false" do
        expect(subject.sets_seen_flags_on_fetch?).to be false
      end
    end
  end
end
