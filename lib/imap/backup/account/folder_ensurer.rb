require "imap/backup/serializer/directory"
require "imap/backup/serializer/folder_maker"
require "imap/backup/serializer/files/path"

module Imap; end

module Imap::Backup
  class Account; end

  # Handles creation of directories for backup storage
  class Account::FolderEnsurer
    # @param account [Account] the account to check
    def initialize(account:)
      @account = account
    end

    # Ensures the account's base directory exists and sets its permissions
    # @raise [RuntimeError] is the account's backup path is not set
    # @return [void]
    def run
      raise "The backup path for #{account.username} is not set" if !account.local_path

      if !parent_exists?
        raise "The backup path's parent directory '#{files_path.base_path}' does not exist"
      end

      Serializer::FolderMaker.new(
        files_path: files_path,
        permissions: Serializer::Directory::DIRECTORY_PERMISSIONS
      ).run
    end

    private

    attr_reader :account

    def files_path
      @files_path ||= begin
        base_path = File.dirname(account.local_path)
        folder_name = File.basename(account.local_path)
        Serializer::Files::Path.new(
          base_path: base_path,
          folder_name: folder_name
        )
      end
    end

    def parent_exists?
      File.directory?(files_path.base_path)
    end
  end
end
