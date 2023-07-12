require "ostruct"

module Imap::Backup
  describe Account::Connection do
    subject { described_class.new(account) }

    let(:account) { "account" }

    describe "#restore" do
      let(:serialized_folders) { instance_double(Account::SerializedFolders) }
      let(:uploader) { instance_double(Uploader, run: nil) }

      before do
        allow(Account::SerializedFolders).to receive(:new) { serialized_folders }
        allow(serialized_folders).to receive(:each).and_yield("folder", "serializer")
        allow(Uploader).to receive(:new) { uploader }
      end

      it "runs the uploader" do
        subject.restore

        expect(uploader).to have_received(:run)
      end
    end
  end
end
