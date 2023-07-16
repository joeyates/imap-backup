require "imap/backup/account/folder_ensurer"

module Imap; end

module Imap::Backup
  class Account; end

  class Account::SerializedFolders
    include Enumerable

    attr_reader :account

    def initialize(account:)
      @account = account
    end

    def each(&block)
      return enum_for(:each) if !block

      glob.each do |path|
        name = path.relative_path_from(base).to_s[0..-6]
        serializer = Serializer.new(account.local_path, name)
        folder = Account::Folder.new(account.client, name)
        block.call(serializer, folder)
      end
    end

    private

    def base
      @base ||= Pathname.new(account.local_path)
    end

    def glob
      @glob ||= begin
        Account::FolderEnsurer.new(account: account).run

        pattern = File.join(account.local_path, "**", "*.imap")
        Pathname.glob(pattern)
      end
    end
  end
end
