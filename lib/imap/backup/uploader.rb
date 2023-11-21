require "imap/backup/account/folder"
require "imap/backup/logger"
require "imap/backup/serializer"

module Imap; end

module Imap::Backup
  # Uploads a backed-up folder
  class Uploader
    # @param folder [Account::Folder] an online folder
    # @param serializer [Serializer] a local folder backup
    def initialize(folder, serializer)
      @folder = folder
      @serializer = serializer
    end

    # Uploads messages that are present in the backup, but not in the online folder
    def run
      if folder.uids.any?
        rename_serialized_folder
      else
        folder.create
        serializer.force_uid_validity(folder.uid_validity)
      end

      return if count.zero?

      Logger.logger.debug "[#{folder.name}] #{count} to restore"
      serializer.each_message(missing_uids).with_index do |message, i|
        upload_message message, i + 1
      end
    end

    private

    attr_reader :folder
    attr_reader :serializer

    def upload_message(message, index)
      return if message.nil?

      log_prefix = "[#{folder.name}] uid: #{message.uid} (#{index}/#{count}) -"
      Logger.logger.debug(
        "#{log_prefix} #{message.body.size} bytes"
      )

      begin
        new_uid = folder.append(message)
        serializer.update_uid(message.uid, new_uid)
      rescue StandardError => e
        Logger.logger.warn "#{log_prefix} append error: #{e}"
      end
    end

    def count
      @count ||= missing_uids.count
    end

    def missing_uids
      serializer.uids - folder.uids
    end

    def rename_serialized_folder
      Logger.logger.debug(
        "There's already a '#{folder.name}' folder with emails"
      )

      # Rename the local folder to a unique name
      new_name = serializer.apply_uid_validity(folder.uid_validity)

      return if !new_name

      # Restore the renamed folder
      Logger.logger.debug(
        "Backup '#{serializer.folder}' renamed and restored to '#{new_name}'"
      )
      @folder = Account::Folder.new(folder.client, new_name)
      folder.create
      @serializer = Serializer.new(serializer.path, new_name)
      serializer.force_uid_validity(@folder.uid_validity)
    end
  end
end
