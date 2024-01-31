require "imap/backup/account/restore"

module Imap::Backup
  RSpec.describe Account::Restore do
    subject { described_class.new(account: account, **options) }

    let(:account) { "account" }
    let(:options) { {} }
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

    context "when a delimiter is provided" do
      let(:options) { {delimiter: "."} }
      let(:delimited_folder) { instance_double(Account::Folder) }
      let(:serializer) { instance_double(Serializer) }

      it "maps destination folders with the delimiter" do
        subject.run

        expect(Account::FolderMapper).to have_received(:new).
          with(hash_including(destination_delimiter: "."))
      end
    end
  end
end
