require "imap/backup/email/provider/fastmail"

module Imap::Backup
  RSpec.describe Email::Provider::Fastmail do
    describe "#host" do
      it "returns host" do
        expect(subject.host).to eq("imap.fastmail.com")
      end
    end
  end
end
