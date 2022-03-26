module Imap::Backup
  class Account; end
  class Account::Connection; end

  class Account::Connection::BackupFolders
    attr_reader :account
    attr_reader :client

    def initialize(client:, account:)
      @client = client
      @account = account
    end

    def run
      names =
        if account.folders&.any?
          account.folders.map { |af| af[:name] }
        else
          Account::Connection::FolderNames.new(client: client, account: account).run
        end

      names.map do |name|
        Account::Folder.new(account.connection, name)
      end
    end
  end
end
