module Imap::Backup
  class Account; end
  class Account::Connection; end

  class Account::Connection::FolderNames
    attr_reader :account
    attr_reader :client

    def initialize(client:, account:)
      @client = client
      @account = account
    end

    def run
      folder_names = client.list

      if folder_names.empty?
        message = "Unable to get folder list for account #{account.username}"
        Logger.logger.info message
        raise message
      end

      folder_names
    end
  end
end
