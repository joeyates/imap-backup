module Imap::Backup
  class Account; end

  class Account::SerializedFolders
    attr_reader :account

    def initialize(account:)
      @account = account
    end

    def each
      return enum_for(:each) if !block_given?

      Account::FolderEnsurer.new(account: account).run

      glob = File.join(account.local_path, "**", "*.imap")
      base = Pathname.new(account.local_path)
      Pathname.glob(glob) do |path|
        name = path.relative_path_from(base).to_s[0..-6]
        serializer = Serializer.new(account.local_path, name)
        folder = Account::Folder.new(account.client, name)
        yield serializer, folder
      end
    end

    def map
      each.map do |serializer, folder|
        yield serializer, folder
      end
    end

    def find
      each.find do |serializer, folder|
        yield serializer, folder
      end
    end
  end
end
