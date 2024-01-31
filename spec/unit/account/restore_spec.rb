require "imap/backup/account/restore"

module Imap::Backup
  RSpec.describe Account::Restore do
    subject { described_class.new(account: account) }

    let(:account) { "account" }
    let(:folder_mapper) { instance_double(Account::FolderMapper) }
    let(:uploader) { instance_double(Uploader, run: nil) }

    before do
      allow(Account::FolderMapper).to receive(:new) { folder_mapper }
      allow(folder_mapper).to receive(:each).and_yield("serializer", "folder")
      allow(Uploader).to receive(:new) { uploader }
    end

    it "runs the uploader" do
      subject.run

      expect(uploader).to have_received(:run)
    end
  end
end
