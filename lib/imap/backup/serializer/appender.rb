module Imap::Backup
  class Serializer::Appender
    attr_reader :imap
    attr_reader :folder
    attr_reader :mbox

    def initialize(folder:, imap:, mbox:)
      @folder = folder
      @imap = imap
      @mbox = mbox
    end

    def run(uid:, message:, flags:)
      raise "Can't add messages without uid_validity" if !imap.uid_validity

      uid = uid.to_i
      existing = imap.get(uid)
      if existing
        Logger.logger.debug(
          "[#{folder}] message #{uid} already downloaded - skipping"
        )
        return
      end

      do_append uid, message, flags
    end

    private

    def do_append(uid, message, flags)
      mboxrd_message = Email::Mboxrd::Message.new(message)
      initial = mbox.length || 0
      mbox_appended = false
      begin
        serialized = mboxrd_message.to_serialized
        mbox.append serialized
        mbox_appended = true
        imap.append uid, serialized.length, flags
      rescue StandardError => e
        mbox.rewind(initial) if mbox_appended

        error = <<-ERROR.gsub(/^\s*/m, "")
          [#{folder}] failed to append message #{uid}:
          #{message}. #{e}:
          #{e.backtrace.join("\n")}"
        ERROR
        Logger.logger.warn error
      end
    end
  end
end
