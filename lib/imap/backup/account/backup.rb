require "imap/backup/account/backup_folders"
require "imap/backup/account/folder_backup"
require "imap/backup/account/local_only_folder_deleter"
require "imap/backup/account/locker"

module Imap; end

module Imap::Backup
  class Account; end

  # Carries out the backup of the configured folders of the account
  class Account::Backup
    # @param account [Account] the account to back up
    # @param refresh [Boolean] true to refresh folder metadata even if mirror is disabled
    def initialize(account:, refresh: false)
      @account = account
      @refresh = refresh
    end

    # Runs the backup
    # @return [void]
    def run
      Logger.logger.info "Running backup of account '#{account.username}'"
      # start the connection so we get logging messages in the right order
      account.client.login

      ensure_directory
      delete_local_only_folders if account.mirror_mode

      if backup_folders.none?
        Logger.logger.warn "No folders found to backup for account '#{account.username}'"
        return
      end

      locker.with_lock do
        perform_backup
      end
    end

    private

    attr_reader :account
    attr_reader :refresh

    def backup_folders
      @backup_folders ||= Account::BackupFolders.new(
        client: account.client, account: account
      ).to_a
    end

    def delete_local_only_folders
      Account::LocalOnlyFolderDeleter.new(account: account).run
    end

    def ensure_directory
      Serializer::DirectoryMaker.new(files_path: account.files_path).run
    end

    def locker
      @locker ||= Account::Locker.new(account: account)
    end

    def perform_backup
      Logger.logger.debug "Starting backup of #{backup_folders.count} folders"
      backup_folders.each do |folder|
        Account::FolderBackup.new(account: account, folder: folder, refresh: refresh).run
      end
      Logger.logger.debug "Backup of account '#{account.username}' complete"
    end
  end
end
