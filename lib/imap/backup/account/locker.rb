require "imap/backup/account/folder_ensurer"
require "imap/backup/lockfile"

module Imap; end

module Imap::Backup
  class Account; end

  class Account::Locker
    attr_reader :account

    # @param account [Account] the account whose backup must be locked
    def initialize(account:)
      @account = account
    end

    def with_lock(&block)
      lockfile = Lockfile.new(path: account.lockfile_path)
      if lockfile.exists?
        if !lockfile.stale?
          raise Lockfile::LockfileExistsError,
                "Lockfile '#{account.lockfile_path}' exists and is not stale."
        end

        Logger.logger.info("Stale lockfile '#{account.lockfile_path}' found. Removing it.")
        lockfile.remove
      else
        Account::FolderEnsurer.new(account: account).run
      end

      lockfile.with_lock do
        block.call
      end
    end
  end
end
