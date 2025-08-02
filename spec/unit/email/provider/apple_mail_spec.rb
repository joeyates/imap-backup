require "imap/backup/email/provider/apple_mail"

module Imap::Backup
  RSpec.describe Email::Provider::AppleMail do
    describe "#host" do
      it "returns host" do
        expect(subject.host).to eq("imap.mail.me.com")
      end
    end

    describe "#root" do
      it "is an empty string" do
        expect(subject.root).to eq("")
      end
    end

    describe "#sets_seen_flags_on_fetch?" do
      it "is true" do
        expect(subject.sets_seen_flags_on_fetch?).to be true
      end
    end
  end
end
