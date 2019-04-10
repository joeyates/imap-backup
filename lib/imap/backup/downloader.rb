module Imap::Backup
  class Downloader
    attr_reader :folder
    attr_reader :serializer

    def initialize(folder, serializer)
      @folder, @serializer = folder, serializer
    end

    def run
      uids = folder.uids - serializer.uids
      count = uids.count
      Imap::Backup.logger.debug "[#{folder.name}] #{count} new messages"
      uids.each.with_index do |uid, i|
        message = folder.fetch(uid)
        log_prefix = "[#{folder.name}] uid: #{uid} (#{i + 1}/#{count}) -"
        if message.nil?
          Imap::Backup.logger.debug("#{log_prefix} not available - skipped")
          next
        end
        Imap::Backup.logger.debug(
          "#{log_prefix} #{message['RFC822'].size} bytes"
        )
        serializer.save(uid, message)
      end
    end
  end
end
