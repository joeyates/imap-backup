module Imap::Backup
  RSpec.describe Client::AppleMail do
    subject { described_class.new("server", account, {}) }

    let(:account) { instance_double(Account) }

    describe "#provider_root" do
      it "is an empty string" do
        expect(subject.provider_root).to eq("")
      end
    end
  end
end
