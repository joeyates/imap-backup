require "imap/backup/email/provider/gmail"

module Imap::Backup
  RSpec.describe Email::Provider::GMail do
    describe "#folder_ignore_tags" do
      it "returns Noselect" do
        expect(subject.folder_ignore_tags).to eq([:Noselect])
      end
    end

    describe "#host" do
      it "returns host" do
        expect(subject.host).to eq("imap.gmail.com")
      end
    end
  end
end
