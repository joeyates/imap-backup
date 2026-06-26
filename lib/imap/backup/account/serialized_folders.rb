require "pathname"

require "imap/backup/account/folder"
require "imap/backup/naming"
require "imap/backup/serializer"
require "imap/backup/serializer/directory_maker"
require "imap/backup/serializer/files/path"

module Imap; end

module Imap::Backup
  class Account; end

  # Enumerates over an account's backed-up folders
  class Account::SerializedFolders
    include Enumerable

    # @param account [Account] the account whose serialized folders are iterated
    def initialize(account:)
      @account = account
    end

    # Runs the enumeration over local serializers and remote folders
    # @yieldparam serializer [Serializer] the folder's serializer
    # @yieldparam folder [Account::Folder] the online folder
    # @return [void]
    def each(&block)
      return enum_for(:each) if !block

      glob.each do |path|
        name = folder_name(path)
        files_path = Serializer::Files::Path.new(
          base_path: account.local_path, folder_name: name
        )
        serializer = Serializer.new(files_path: files_path)
        folder = Account::Folder.new(account.client, name)
        block.call(serializer, folder)
      end
    end

    # Runs the enumeration over each local serializer
    # @yieldparam serializer [Serializer] the folder's serializer
    # @return [void]
    def each_key(&block)
      return enum_for(:each_key) if !block

      glob.each do |path|
        name = folder_name(path)
        files_path = Serializer::Files::Path.new(
          base_path: account.local_path, folder_name: name
        )
        serializer = Serializer.new(files_path: files_path)
        block.call(serializer)
      end
    end

    # Runs the enumeration over each remote folder
    # @yieldparam folder [Account::Folder] the online folder
    # @return [void]
    def each_value(&block)
      return enum_for(:each_value) if !block

      glob.each do |path|
        name = folder_name(path)
        folder = Account::Folder.new(account.client, name)
        block.call(folder)
      end
    end

    private

    attr_reader :account

    def folder_name(path)
      local_name = path.relative_path_from(base).to_s[0..-6]
      Naming.from_local_path(local_name)
    end

    def base
      @base ||= Pathname.new(account.local_path)
    end

    def glob
      @glob ||= begin
        files_path = Serializer::Files::Path.new(
          base_path: account.local_path, folder_name: nil
        )
        Serializer::DirectoryMaker.new(files_path: files_path).run

        pattern = File.join(account.local_path, "**", "*.imap")
        Pathname.glob(pattern)
      end
    end
  end
end
