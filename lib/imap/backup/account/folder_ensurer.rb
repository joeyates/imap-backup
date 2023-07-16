require "imap/backup/serializer/directory"
require "imap/backup/serializer/folder_maker"

module Imap; end

module Imap::Backup
  class Account; end

  class Account::FolderEnsurer
    attr_reader :account

    def initialize(account:)
      @account = account
    end

    def run
      raise "The backup path for #{account.username} is not set" if !account.local_path

      Serializer::FolderMaker.new(
        base: File.dirname(account.local_path),
        path: File.basename(account.local_path),
        permissions: Serializer::Directory::DIRECTORY_PERMISSIONS
      ).run
    end
  end
end
