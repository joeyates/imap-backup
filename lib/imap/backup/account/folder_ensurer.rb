require "imap/backup/serializer/directory"
require "imap/backup/utils"

module Imap::Backup
  class Account; end

  class Account::FolderEnsurer
    attr_reader :account

    def initialize(account:)
      @account = account
    end

    def run
      raise "The backup path for #{account.username} is not set" if !account.local_path

      Utils.make_folder(
        File.dirname(account.local_path),
        File.basename(account.local_path),
        Serializer::Directory::DIRECTORY_PERMISSIONS
      )
    end
  end
end
