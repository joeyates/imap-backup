module Imap::Backup
  class Account; end

  class Account::BackupFolders
    attr_reader :account
    attr_reader :client

    def initialize(client:, account:)
      @client = client
      @account = account
    end

    def each
      return enum_for(:each) if !block_given?

      all_names = client.list

      configured =
        case
        when account.folders&.any?
          account.folders.map { |af| af[:name] }
        when account.folder_blacklist
          []
        else
          all_names
        end

      names =
        if account.folder_blacklist
          all_names - configured
        else
          all_names & configured
        end

      names.each { |name| yield Account::Folder.new(client, name) }
    end

    def map
      each.map do |folder|
        yield folder
      end
    end
  end
end
