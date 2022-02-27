module Imap::Backup
  RSpec.describe Client::AppleMail do
    describe "#provider_root" do
      it "is an empty string" do
        expect(subject.provider_root).to eq("")
      end
    end
  end
end
