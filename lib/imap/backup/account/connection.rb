require "imap/backup/account/backup_folders"
require "imap/backup/account/folder_ensurer"
require "imap/backup/account/serialized_folders"
require "imap/backup/flag_refresher"
require "imap/backup/local_only_message_deleter"

module Imap::Backup
  class Account; end

  class Account::Connection
    attr_reader :account

    def initialize(account)
      @account = account
    end

    def run_backup(refresh: false)
      Logger.logger.info "Running backup of account: #{account.username}"
      # start the connection so we get logging messages in the right order
      account.client
      Account::FolderEnsurer.new(account: account).run
      if account.mirror_mode
        # Delete serialized folders that are not to be backed up
        backup_folders = Account::BackupFolders.new(
          client: account.client, account: account
        )
        wanted = backup_folders.map(&:name)
        serialized_folders = Account::SerializedFolders.new(account: account)
        serialized_folders.each do |serializer, _folder|
          serializer.delete if !wanted.include?(serializer.folder)
        end
      end
      each_folder do |folder, serializer|
        begin
          next if !folder.exist?
        rescue Encoding::UndefinedConversionError
          message = "Skipping backup for '#{folder.name}' " \
                    "as it is not UTF-7 encoded correctly"
          Logger.logger.info message
          next
        end

        Logger.logger.debug "[#{folder.name}] running backup"
        serializer.apply_uid_validity(folder.uid_validity)
        Downloader.new(
          folder,
          serializer,
          multi_fetch_size: account.multi_fetch_size,
          reset_seen_flags_after_fetch: account.reset_seen_flags_after_fetch
        ).run
        if account.mirror_mode
          Logger.logger.info "Mirror mode - Deleting messages only present locally"
          LocalOnlyMessageDeleter.new(folder, serializer).run
        end
        FlagRefresher.new(folder, serializer).run if account.mirror_mode || refresh
      end
    end

    def restore
      serialized_folders = Account::SerializedFolders.new(account: account)
      serialized_folders.each do |serializer, folder|
        Uploader.new(folder, serializer).run
      end
    end

    private

    def each_folder
      backup_folders = Account::BackupFolders.new(
        client: account.client, account: account
      )
      backup_folders.each do |folder|
        serializer = Serializer.new(account.local_path, folder.name)
        yield folder, serializer
      end
    end
  end
end
