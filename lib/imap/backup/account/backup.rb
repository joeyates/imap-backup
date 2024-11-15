require "imap/backup/account/backup_folders"
require "imap/backup/account/folder_backup"
require "imap/backup/account/folder_ensurer"
require "imap/backup/account/local_only_folder_deleter"

module Imap; end

module Imap::Backup
  class Account; end

  # Carries out the backup of the configured folders of the account
  class Account::Backup
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

      run_pre_backup_tasks
      backup_folders = Account::BackupFolders.new(
        client: account.client, account: account
      ).to_a
      if backup_folders.none?
        Logger.logger.warn "No folders found to backup for account '#{account.username}'"
        return
      end
      Logger.logger.debug "Starting backup of #{backup_folders.count} folders"
      backup_folders.each do |folder|
        Account::FolderBackup.new(account: account, folder: folder, refresh: refresh).run
      end
      Logger.logger.debug "Backup of account '#{account.username}' complete"
    end

    private

    attr_reader :account
    attr_reader :refresh

    def run_pre_backup_tasks
      Account::FolderEnsurer.new(account: account).run
      Account::LocalOnlyFolderDeleter.new(account: account).run if account.mirror_mode
    end
  end
end
