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

      names =
        if account.folders&.any?
          account.folders.map { |af| af[:name] }
        else
          if account.folder_blacklist
            []
          else
            all_names
          end
        end

      all_names.map do |name|
        backup =
          if account.folder_blacklist
            !names.include?(name)
          else
            names.include?(name)
          end
        next if !backup

        Account::Folder.new(account.connection, name)
      end.compact
    end
  end
end
