require "imap/backup/account/folder_ensurer"
require "imap/backup/account/local_only_folder_deleter"
require "imap/backup/account/serialized_folders"
require "imap/backup/serializer/delayed_metadata_serializer"
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
      backup_folders = Account::BackupFolders.new(
        client: account.client, account: account
      )
      backup_folders.each do |folder|
        backup_folder folder
      end
    end

    private

    def backup_folder(folder)
      serializer = Serializer.new(account.local_path, folder.name)
      begin
        return if !folder.exist?
      rescue Encoding::UndefinedConversionError
        message = "Skipping backup for '#{folder.name}' " \
                  "as it is not UTF-7 encoded correctly"
        Logger.logger.info message
        return
      end

      Logger.logger.debug "[#{folder.name}] running backup"

      serializer.apply_uid_validity(folder.uid_validity)

      download_serializer =
        case account.download_strategy
        when "direct"
          serializer
        when "delay_metadata"
          Serializer::DelayedMetadataSerializer.new(serializer: serializer)
        else
          raise "Unknown download strategy '#{account.download_strategy}'"
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
      rescue StandardError => e
        message = <<~ERROR
          #{self.class} error #{e}
          #{e.backtrace.join("\n")}
        ERROR
        Logger.logger.error message
        download_serializer.rollback
        raise e
      rescue SignalException => e
        Logger.logger.error "#{self.class} handling #{e.class}"
        download_serializer.rollback
        raise e
      end
      # rubocop:enable Lint/RescueException
      if account.mirror_mode
        Logger.logger.info "Mirror mode - Deleting messages only present locally"
        LocalOnlyMessageDeleter.new(folder, serializer).run
      end
      FlagRefresher.new(folder, serializer).run if account.mirror_mode || refresh
    end
  end
end
