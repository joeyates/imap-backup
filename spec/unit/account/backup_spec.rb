require "imap/backup/account/backup"

require "imap/backup/account/locker"
require "imap/backup/client/default"
require "imap/backup/downloader"
require "imap/backup/serializer"

module Imap::Backup
  RSpec.describe Account::Backup do
    subject { described_class.new(account: account, refresh: refresh) }

    let(:account) do
      instance_double(
        Account,
        username: "username",
        client: client,
        files_path: files_path,
        lockfile_path: "lockfile_path",
        mirror_mode: mirror_mode,
        download_strategy: "direct",
        reset_seen_flags_after_fetch: reset_seen_flags_after_fetch
      )
    end
    let(:backup_folders) { instance_double(Account::BackupFolders, to_a: backup_folders_result) }
    let(:backup_folders_result) { [folder] }
    let(:client) { instance_double(Client::Default, login: nil) }
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
    let(:serializer) { instance_double(Serializer, apply_uid_validity: nil) }
    let(:locker) { instance_double(Account::Locker, with_lock: nil) }
    let(:directory_maker) { instance_double(Serializer::DirectoryMaker, run: nil) }
    let(:files_path) { instance_double(Serializer::Files::Path, base_path: "local_path", folder_name: nil) }
    let(:folder_backup) { instance_double(Account::FolderBackup, run: nil) }

    before do
      allow(Account::BackupFolders).to receive(:new) { backup_folders }
      allow(Account::FolderBackup).to receive(:new) { folder_backup }
      allow(Account::LocalOnlyFolderDeleter).to receive(:new) { local_only_folder_deleter }
      allow(Account::Locker).to receive(:new).with(account: account) { locker }
      allow(Downloader).to receive(:new) { downloader }
      allow(LocalOnlyMessageDeleter).to receive(:new) { local_only_message_deleter }
      allow(Serializer).to receive(:new) { serializer }
      allow(Serializer::DirectoryMaker).to receive(:new) { directory_maker }
      allow(serializer).to receive(:transaction).and_yield
      allow(locker).to receive(:with_lock).and_yield
    end

    it "ensures the backup directory exists" do
      expect(directory_maker).to receive(:run)

      subject.run
    end

    it "locks the account during backup" do
      subject.run

      expect(locker).to have_received(:with_lock)
    end

    it "runs folder backups" do
      subject.run

      expect(folder_backup).to have_received(:run)
    end

    it "doesn't delete unwanted local folders" do
      subject.run

      expect(local_only_folder_deleter).to_not have_received(:run)
    end

    context "when in mirror_mode" do
      let(:mirror_mode) { true }

      it "deletes unwanted local folders" do
        subject.run

        expect(local_only_folder_deleter).to have_received(:run)
      end
    end

    context "when no folders are available" do
      let(:backup_folders_result) { [] }

      before { allow(Logger.logger).to receive(:warn) }

      it "does not lock" do
        subject.run

        expect(locker).to_not have_received(:with_lock)
      end

      it "prints a warning" do
        subject.run

        expect(Logger.logger).
          to have_received(:warn).
          with("No folders found to backup for account 'username'")
      end
    end
  end
end
