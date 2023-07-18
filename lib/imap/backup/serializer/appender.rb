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

    def single(uid:, message:, flags:)
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
        do_append uid, message, flags
      rescue StandardError => e
        raise <<-ERROR.gsub(/^\s*/m, "")
          [#{folder}] failed to append message #{uid}:
          #{message}. #{e}:
          #{e.backtrace.join("\n")}"
        ERROR
      end
    end

    def multi(appends)
      rollback_on_error do
        appends.each do |a|
          do_append a[:uid], a[:message], a[:flags]
        end
      end
    end

    private

    def do_append(uid, message, flags)
      mboxrd_message = Email::Mboxrd::Message.new(message)
      serialized = mboxrd_message.to_serialized
      mbox.append serialized
      imap.append uid, serialized.length, flags: flags
    end

    def rollback_on_error(&block)
      imap.transaction do
        mbox.transaction do
          block.call
        rescue StandardError => e
          Logger.logger.error e
          imap.rollback
          mbox.rollback
        end
      end
    end
  end
end
