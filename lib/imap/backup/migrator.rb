module Imap::Backup
  class Migrator
    attr_reader :folder
    attr_reader :reset
    attr_reader :serializer

    def initialize(serializer, folder, reset: false)
      @folder = folder
      @reset = reset
      @serializer = serializer
    end

    def run
      count = serializer.uids.count
      folder.create
      ensure_destination_empty!

      Logger.logger.debug "[#{folder.name}] #{count} to migrate"
      serializer.each_message(serializer.uids).with_index do |message, i|
        next if message.nil?

        log_prefix = "[#{folder.name}] uid: #{message.uid} (#{i + 1}/#{count}) -"
        Logger.logger.debug(
          "#{log_prefix} #{message.body.size} bytes"
        )

        begin
          folder.append(message)
        rescue StandardError => e
          Logger.logger.warn "#{log_prefix} append error: #{e}"
        end
      end
    end

    private

    def ensure_destination_empty!
      if reset
        folder.clear
      else
        fail_if_destination_not_empty!
      end
    end

    def fail_if_destination_not_empty!
      return if folder.uids.empty?

      raise <<~ERROR
        The destination folder '#{folder.name}' is not empty.
        Pass the --reset flag if you want to clear existing emails from destination
        folders before uploading.
      ERROR
    end
  end
end
