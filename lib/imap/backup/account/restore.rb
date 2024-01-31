require "imap/backup/account/folder_mapper"
require "imap/backup/uploader"

module Imap; end

module Imap::Backup
  class Account; end

  # Restores all backed up folders to the server
  class Account::Restore
    def initialize(account:, delimiter: "/", prefix: "")
      @account = account
      @destination_delimiter = delimiter
      @destination_prefix = prefix
    end

    # Runs the restore operation
    # @return [void]
    def run
      folders.each do |serializer, folder|
        Uploader.new(folder, serializer).run
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
  end
end
