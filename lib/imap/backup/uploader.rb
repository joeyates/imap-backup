module Imap::Backup
  class Uploader
    attr_reader :folder
    attr_reader :serializer

    def initialize(folder, serializer)
      @folder = folder
      @serializer = serializer
    end

    def run
      count = missing_uids.count
      return if count.zero?

      Imap::Backup.logger.debug "[#{folder.name}] #{count} to restore"
      serializer.each_message(missing_uids).with_index do |(uid, message), i|
        next if message.nil?

        log_prefix = "[#{folder.name}] uid: #{uid} (#{i + 1}/#{count}) -"
        Imap::Backup.logger.debug(
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
  end
end
