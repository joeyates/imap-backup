require "imap/backup/account/folder_ensurer"

module Imap::Backup
  class Account; end

  class Account::SerializedFolders
    attr_reader :account

    def initialize(account:)
      @account = account
    end

    def each(&block)
      return enum_for(:each) if !block

      Account::FolderEnsurer.new(account: account).run

      glob = File.join(account.local_path, "**", "*.imap")
      base = Pathname.new(account.local_path)
      Pathname.glob(glob) do |path|
        name = path.relative_path_from(base).to_s[0..-6]
        serializer = Serializer.new(account.local_path, name)
        folder = Account::Folder.new(account.client, name)
        block.call(serializer, folder)
      end
    end

    def map(&block)
      each.map do |serializer, folder|
        block.call(serializer, folder)
      end
    end

    def find(&block)
      each.find do |serializer, folder|
        block.call(serializer, folder)
      end
    end
  end
end
