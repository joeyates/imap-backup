require "imap/backup/account/folder_ensurer"
require "imap/backup/account/local_only_folder_deleter"
require "imap/backup/account/serialized_folders"
require "imap/backup/serializer/delayed_metadata_serializer"
require "imap/backup/serializer/delayed_writes_serializer"
require "imap/backup/downloader"
require "imap/backup/flag_refresher"
require "imap/backup/local_only_message_deleter"

module Imap; end

module Imap::Backup
  class Account; end

  class Account::Backup
    attr_reader :account
    attr_reader :refresh

    def initialize(account:, refresh: false)
      @account = account
      @refresh = refresh
    end

    def run
      Logger.logger.info "Running backup of account: #{account.username}"
      # start the connection so we get logging messages in the right order
      account.client

      Account::FolderEnsurer.new(account: account).run
      Account::LocalOnlyFolderDeleter.new(account: account).run if account.mirror_mode
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

        download_serializer =
          case account.download_strategy
          when "direct"
            serializer
          when "delay_metadata"
            Serializer::DelayedMetadataSerializer.new(serializer: serializer)
          when "delay_all"
            Serializer::DelayedWritesSerializer.new(serializer: serializer)
          end

        downloader = Downloader.new(
          folder,
          download_serializer,
          multi_fetch_size: account.multi_fetch_size,
          reset_seen_flags_after_fetch: account.reset_seen_flags_after_fetch
        )
        # rubocop:disable Lint/RescueException
        download_serializer.transaction do
          downloader.run
        rescue Exception
          download_serializer.rollback
          raise
        end
        # rubocop:enable Lint/RescueException
        if account.mirror_mode
          Logger.logger.info "Mirror mode - Deleting messages only present locally"
          LocalOnlyMessageDeleter.new(folder, serializer).run
        end
        FlagRefresher.new(folder, serializer).run if account.mirror_mode || refresh
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
