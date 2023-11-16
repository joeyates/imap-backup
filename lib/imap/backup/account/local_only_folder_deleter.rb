require "imap/backup/account/backup_folders"
require "imap/backup/account/serialized_folders"

module Imap; end

module Imap::Backup
  class Account; end

  # Deletes serialized folders that are not configured to be backed up.
  # This is used in mirror mode, where local copies are only kept as long as they
  # exist on the server.
  class Account::LocalOnlyFolderDeleter
    attr_reader :account

    def initialize(account:)
      @account = account
    end

    def run
      backup_folders = Account::BackupFolders.new(
        client: account.client, account: account
      )
      wanted = backup_folders.map(&:name)
      serialized_folders = Account::SerializedFolders.new(account: account)
      serialized_folders.each do |serializer, _folder|
        serializer.delete if !wanted.include?(serializer.folder)
      end
    end
  end
end
