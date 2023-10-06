require "email/mboxrd/message"

module Imap; end

module Imap::Backup
  class Serializer; end

  class Serializer::Appender
    attr_reader :imap
    attr_reader :folder
    attr_reader :mbox

    def initialize(folder:, imap:, mbox:)
      @folder = folder
      @imap = imap
      @mbox = mbox
    end

    def append(uid:, message:, flags:)
      raise "Can't add messages without uid_validity" if !imap.uid_validity

      uid = uid.to_i
      existing = imap.get(uid)
      if existing
        Logger.logger.debug(
          "[#{folder}] message #{uid} already downloaded - skipping"
        )
        return
      end

      rollback_on_error do
        serialized = to_serialized(message)
        mbox.append serialized
        imap.append uid, serialized.bytesize, flags: flags
      rescue StandardError => e
        raise <<-ERROR.gsub(/^\s*/m, "")
          [#{folder}] failed to append message #{uid}: #{message}.
          #{e}:
          #{e.backtrace.join("\n")}"
        ERROR
      end
    end

    private

    def to_serialized(message)
      mboxrd_message = Email::Mboxrd::Message.new(message)
      mboxrd_message.to_serialized
    end

    def rollback_on_error(&block)
      imap.transaction do
        mbox.transaction do
          block.call
        rescue StandardError => e
          Logger.logger.error e
          imap.rollback
          mbox.rollback
        rescue SignalException => e
          Logger.logger.error e
          imap.rollback
          mbox.rollback
          raise
        end
      end
    end
  end
end
