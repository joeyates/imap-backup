require "imap/backup/email/provider/purelymail"

module Imap::Backup
  RSpec.describe Email::Provider::Purelymail do
    describe "#host" do
      it "returns host" do
        expect(subject.host).to eq("mailserver.purelymail.com")
      end
    end

    describe "#sets_seen_flags_on_fetch?" do
      it "is true" do
        expect(subject.sets_seen_flags_on_fetch?).to be true
      end
    end
  end
end
