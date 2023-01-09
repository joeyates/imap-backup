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
      all_names = Account::Connection::FolderNames.new(client: client, account: account).run

      configured =
        if account.folders&.any?
          account.folders.map { |af| af[:name] }
        else
          if account.folder_blacklist
            []
          else
            all_names
          end
        end

      names =
        if account.folder_blacklist
          all_names - configured
        else
          all_names & configured
        end

      names.map { |name | Account::Folder.new(account.connection, name) }
    end
  end
end
