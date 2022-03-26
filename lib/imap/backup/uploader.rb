module Imap::Backup
  class Uploader
    attr_reader :folder
    attr_reader :serializer

    def initialize(folder, serializer)
      @folder = folder
      @serializer = serializer
    end

    def run
      existing_uids = folder.uids
      if existing_uids.any?
        rename_serialized_folder
      else
        folder.create
        serializer.force_uid_validity(folder.uid_validity)
      end

      count = missing_uids.count
      return if count.zero?

      Logger.logger.debug "[#{folder.name}] #{count} to restore"
      serializer.each_message(missing_uids).with_index do |(uid, message), i|
        next if message.nil?

        log_prefix = "[#{folder.name}] uid: #{uid} (#{i + 1}/#{count}) -"
        Logger.logger.debug(
          "#{log_prefix} #{message.supplied_body.size} bytes"
        )

        new_uid = folder.append(message)
        serializer.update_uid(uid, new_uid)
      end
    end

    private

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
      @folder = Account::Folder.new(folder.connection, new_name)
      folder.create
      @serializer = Serializer.new(serializer.path, new_name)
      serializer.force_uid_validity(@folder.uid_validity)
    end
  end
end
