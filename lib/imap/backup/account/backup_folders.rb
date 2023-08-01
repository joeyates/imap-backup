module Imap; end

module Imap::Backup
  class Account; end

  class Account::BackupFolders
    include Enumerable

    attr_reader :account
    attr_reader :client

    def initialize(client:, account:)
      @client = client
      @account = account
    end

    def each(&block)
      return enum_for(:each) if !block

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

      names.each { |name| block.call(Account::Folder.new(client, name)) }
    end

    def map(&block)
      each.map do |folder|
        block.call(folder)
      end
    end
  end
end
