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
      Logger.logger.debug "Running backup for folder '#{folder.name}'"

      folder_ok = folder_ok?
      return if !folder_ok

      serializer.apply_uid_validity(folder.uid_validity)

      serializer.transaction do
        downloader.run
        FlagRefresher.new(folder, serializer).run if account.mirror_mode || refresh
      end
      # After the transaction the serializer will have any appended messages
      # so we can check differences between the server and the local backup
      LocalOnlyMessageDeleter.new(folder, raw_serializer).run if account.mirror_mode
      Logger.logger.debug "Backup for folder '#{folder.name}' complete"
    end

    private

    attr_reader :account
    attr_reader :folder
    attr_reader :refresh

    def folder_ok?
      begin
        if !folder.exist?
          Logger.logger.info "Skipping backup for folder '#{folder.name}' as it does not exist"
          return false
        end
      rescue Encoding::UndefinedConversionError
        message = "Skipping backup for '#{folder.name}' " \
                  "as it's name is not UTF-7 encoded correctly"
        Logger.logger.info message
        return false
      end

      true
    end

    def downloader
      @downloader ||= Downloader.new(
        folder,
        serializer,
        multi_fetch_size: account.multi_fetch_size,
        reset_seen_flags_after_fetch: account.reset_seen_flags_after_fetch
      )
    end

    def serializer
      @serializer ||=
        case account.download_strategy
        when "direct"
          raw_serializer
        when "delay_metadata"
          Serializer::DelayedMetadataSerializer.new(serializer: raw_serializer)
        else
          raise "Unknown download strategy '#{account.download_strategy}'"
        end
    end

    def raw_serializer
      @raw_serializer ||= Serializer.new(account.local_path, folder.name)
    end
  end
end
