require "imap/backup/account/restore"

require "imap/backup/account/locker"

module Imap::Backup
  RSpec.describe Account::Restore do
    subject { described_class.new(account: account, **options) }

    let(:account) { "account" }
    let(:options) { {} }
    let(:folder_mapper) { instance_double(Account::FolderMapper) }
    let(:uploader) { instance_double(Uploader, run: nil) }
    let(:locker) { instance_double(Account::Locker, with_lock: nil) }

    before do
      allow(Account::FolderMapper).to receive(:new) { folder_mapper }
      allow(folder_mapper).to receive(:each).and_yield("serializer", "folder")
      allow(Uploader).to receive(:new) { uploader }
      allow(Account::Locker).to receive(:new).with(account: account) { locker }
      allow(locker).to receive(:with_lock).and_yield
    end

    it "runs the uploader" do
      subject.run

      expect(uploader).to have_received(:run)
    end

    it "locks the account during the restore" do
      subject.run

      expect(locker).to have_received(:with_lock)
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

    context "when a prefix is provided" do
      let(:options) { {prefix: "."} }
      let(:delimited_folder) { instance_double(Account::Folder) }
      let(:serializer) { instance_double(Serializer) }

      it "maps destination folders with the prefix" do
        subject.run

        expect(Account::FolderMapper).to have_received(:new).
          with(hash_including(destination_prefix: "."))
      end
    end
  end
end
