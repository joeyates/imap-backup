require "imap/backup/account/backup_folders"
require "imap/backup/account/folder_backup"
require "imap/backup/account/folder_ensurer"
require "imap/backup/account/local_only_folder_deleter"

module Imap; end

module Imap::Backup
  class Account; end

  class Account::Backup
    attr_reader :account
    attr_reader :refresh

    def initialize(account:, refresh: false)
      @account = account
      @refresh = refresh
    end

    def run
      Logger.logger.info "Running backup of account: #{account.username}"
      # start the connection so we get logging messages in the right order
      account.client

      Account::FolderEnsurer.new(account: account).run
      Account::LocalOnlyFolderDeleter.new(account: account).run if account.mirror_mode
      backup_folders = Account::BackupFolders.new(
        client: account.client, account: account
      )
      if backup_folders.none?
        Logger.logger.warn "Account #{account.username}: No folders found to backup"
        return
      end
      backup_folders.each do |folder|
        Account::FolderBackup.new(account: account, folder: folder, refresh: refresh).run
      end
    end
  end
end
