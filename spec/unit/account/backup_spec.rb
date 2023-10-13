require "imap/backup/account/backup"

require "imap/backup/client/default"
require "imap/backup/downloader"
require "imap/backup/flag_refresher"
require "imap/backup/local_only_message_deleter"
require "imap/backup/serializer"

module Imap::Backup
  RSpec.describe Account::Backup do
    subject { described_class.new(account: account, refresh: refresh) }

    let(:account) do
      instance_double(
        Account,
        username: "username",
        client: client,
        local_path: "local_path",
        mirror_mode: mirror_mode,
        multi_fetch_size: 42,
        download_strategy: "direct",
        reset_seen_flags_after_fetch: reset_seen_flags_after_fetch
      )
    end
    let(:backup_folders) { instance_double(Account::BackupFolders, none?: false) }
    let(:client) { instance_double(Client::Default, login: nil) }
    let(:downloader) { instance_double(Downloader, run: nil) }
    let(:folder) do
      instance_double(
        Account::Folder,
        name: "folder_name",
        exist?: folder_exists,
        uid_validity: 123
      )
    end
    let(:mirror_mode) { false }
    let(:folder_exists) { true }
    let(:refresh) { false }
    let(:reset_seen_flags_after_fetch) { false }
    let(:flag_refresher) { instance_double(FlagRefresher, run: nil) }
    let(:local_only_folder_deleter) { instance_double(Account::LocalOnlyFolderDeleter, run: nil) }
    let(:local_only_message_deleter) { instance_double(LocalOnlyMessageDeleter, run: nil) }
    let(:folder_ensurer) { instance_double(Account::FolderEnsurer, run: nil) }
    let(:serializer) { instance_double(Serializer, apply_uid_validity: nil) }

    before do
      allow(Downloader).to receive(:new) { downloader }
      allow(Account::BackupFolders).to receive(:new) { backup_folders }
      allow(FlagRefresher).to receive(:new) { flag_refresher }
      allow(Account::LocalOnlyFolderDeleter).to receive(:new) { local_only_folder_deleter }
      allow(LocalOnlyMessageDeleter).to receive(:new) { local_only_message_deleter }
      allow(Account::FolderEnsurer).to receive(:new) { folder_ensurer }
      allow(Serializer).to receive(:new) { serializer }
      allow(serializer).to receive(:transaction).and_yield
      allow(backup_folders).to receive(:each).and_yield(folder)
    end

    it "ensures the backup directory exists" do
      subject.run

      expect(folder_ensurer).to have_received(:run)
    end

    it "runs the downloader" do
      subject.run

      expect(downloader).to have_received(:run)
    end

    it "doesn't delete unwanted local folders" do
      subject.run

      expect(local_only_folder_deleter).to_not have_received(:run)
    end

    it "doesn't delete unwanted local messages" do
      subject.run

      expect(local_only_message_deleter).to_not have_received(:run)
    end

    it "doesn't refresh flags" do
      subject.run

      expect(flag_refresher).to_not have_received(:run)
    end

    it "passes the multi_fetch_size" do
      subject.run

      expect(Downloader).to have_received(:new).
        with(anything, anything, hash_including(multi_fetch_size: 42))
    end

    context "when in mirror_mode" do
      let(:mirror_mode) { true }

      it "deletes unwanted local folders" do
        subject.run

        expect(local_only_folder_deleter).to have_received(:run)
      end

      it "deletes unwanted local messages" do
        subject.run

        expect(local_only_message_deleter).to have_received(:run)
      end

      it "refreshes flags" do
        subject.run

        expect(flag_refresher).to have_received(:run)
      end
    end

    context "when refresh is true" do
      let(:refresh) { true }

      it "refreshes flags" do
        subject.run

        expect(flag_refresher).to have_received(:run)
      end
    end

    context "when reset_seen_flags_after_fetch is set" do
      let(:reset_seen_flags_after_fetch) { true }

      it "passes reset_seen_flags_after_fetch" do
        subject.run

        expect(Downloader).to have_received(:new).
          with(anything, anything, hash_including(reset_seen_flags_after_fetch: true))
      end
    end

    context "when a folder does not exist" do
      let(:folder_exists) { false }

      it "does not run the downloader" do
        expect(downloader).to_not receive(:run)

        subject.run
      end
    end

    context "when a folder name is badly encoded" do
      it "skips the folder" do
        allow(folder).to receive(:exist?).and_raise(Encoding::UndefinedConversionError)

        subject.run

        expect(downloader).to_not have_received(:run)
      end
    end
  end
end
