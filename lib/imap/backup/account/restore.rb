require "imap/backup/account/serialized_folders"

module Imap::Backup
  class Account; end

  class Account::Restore
    attr_reader :account

    def initialize(account:)
      @account = account
    end

    def run
      serialized_folders = Account::SerializedFolders.new(account: account)
      serialized_folders.each do |serializer, folder|
        Uploader.new(folder, serializer).run
      end
    end
  end
end
