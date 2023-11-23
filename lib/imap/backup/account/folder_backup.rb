require "imap/backup/serializer/delayed_metadata_serializer"
require "imap/backup/downloader"
require "imap/backup/flag_refresher"
require "imap/backup/local_only_message_deleter"
require "imap/backup/logger"
require "imap/backup/serializer"

module Imap; end

module Imap::Backup
  class Account; end

  # Implements backup for a single folder
  class Account::FolderBackup
    def initialize(account:, folder:, refresh: false)
      @account = account
      @folder = folder
      @refresh = refresh
    end

    # Runs the backup
    # @raise [RuntimeError] if the configured download strategy is incorrect
    # @return [void]
    def run
      folder_ok = folder_ok?
      return if !folder_ok

      Logger.logger.debug "[#{folder.name}] running backup"

      serializer.apply_uid_validity(folder.uid_validity)

      download_serializer.transaction do
        downloader.run
      end

      clean_up
    end

    private

    attr_reader :account
    attr_reader :folder
    attr_reader :refresh

    def folder_ok?
      begin
        return false if !folder.exist?
      rescue Encoding::UndefinedConversionError
        message = "Skipping backup for '#{folder.name}' " \
                  "as it is not UTF-7 encoded correctly"
        Logger.logger.info message
        return false
      end

      true
    end

    def clean_up
      LocalOnlyMessageDeleter.new(folder, serializer).run if account.mirror_mode
      FlagRefresher.new(folder, serializer).run if account.mirror_mode || refresh
    end

    def downloader
      @downloader ||= Downloader.new(
        folder,
        download_serializer,
        multi_fetch_size: account.multi_fetch_size,
        reset_seen_flags_after_fetch: account.reset_seen_flags_after_fetch
      )
    end

    def download_serializer
      @download_serializer ||=
        case account.download_strategy
        when "direct"
          serializer
        when "delay_metadata"
          Serializer::DelayedMetadataSerializer.new(serializer: serializer)
        else
          raise "Unknown download strategy '#{account.download_strategy}'"
        end
    end

    def serializer
      @serializer ||= Serializer.new(account.local_path, folder.name)
    end
  end
end
