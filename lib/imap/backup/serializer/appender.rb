require "imap/backup/email/mboxrd/message"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Appends messages to the local store
  class Serializer::Appender
    def initialize(folder:, imap:, mbox:)
      @folder = folder
      @imap = imap
      @mbox = mbox
    end

    # Adds a message to the metadata file and the mailbox.
    # Wraps any errors with information about the message that caused them.
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

      begin
        serialized = to_serialized(message)
      rescue StandardError => e
        raise wrap_error(
          error: e,
          note: "failed to serialize message",
          folder: folder,
          uid: uid,
          message: message
        )
      end

      rollback_on_error do
        mbox.append serialized
        imap.append uid, serialized.bytesize, flags: flags
      rescue StandardError => e
        raise wrap_error(
          error: e,
          note: "failed to append message",
          folder: folder,
          uid: uid,
          message: message
        )
      end
    end

    private

    attr_reader :imap
    attr_reader :folder
    attr_reader :mbox

    def wrap_error(error:, note:, folder:, uid:, message:)
      <<-ERROR.gsub(/^\s*/m, "")
        [#{folder}] #{note} #{uid}: #{message}.
        #{error}:
        #{error.backtrace.join("\n")}"
      ERROR
    end

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
