require "imap/backup/account/folder_mapper"
require "imap/backup/account/locker"
require "imap/backup/uploader"

module Imap; end

module Imap::Backup
  class Account; end

  # Restores all backed up folders to the server
  class Account::Restore
    # @param account [Account] the account whose backups will be restored
    # @param delimiter [String] the destination folder delimiter
    # @param prefix [String] a prefix applied to restored folder names
    def initialize(account:, delimiter: "/", prefix: "")
      @account = account
      @destination_delimiter = delimiter
      @destination_prefix = prefix
      @locker = nil
    end

    # Runs the restore operation
    # @return [void]
    def run
      locker.with_lock do
        folders.each do |serializer, folder|
          Uploader.new(folder, serializer).run
        end
      end
    end

    private

    attr_reader :account
    attr_reader :destination_delimiter
    attr_reader :destination_prefix

    def enumerator_options
      {
        account: account,
        destination: account,
        destination_delimiter: destination_delimiter,
        destination_prefix: destination_prefix
      }
    end

    def folders
      Account::FolderMapper.new(**enumerator_options)
    end

    def locker
      @locker ||= Account::Locker.new(account: account)
    end
  end
end
