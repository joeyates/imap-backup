module Imap; end

module Imap::Backup
  class Serializer; end

  class Serializer::FolderIntegrityError < StandardError; end

  # Checks that both the mailbox and its associated metadata file match
  class Serializer::IntegrityChecker
    # @param imap [Imap]
    # @param mbox [Mbox]
    def initialize(imap:, mbox:)
      @imap = imap
      @mbox = mbox
    end

    # Runs the integrity check
    #
    # @raise [FolderIntegrityError] if the files do not match
    # @return [void]
    def run
      Logger.logger.debug(
        "[IntegrityChecker] checking '#{imap.pathname}' against '#{mbox.pathname}'"
      )
      if !imap.valid?
        message = ".imap file '#{imap.pathname}' is corrupt"
        raise Serializer::FolderIntegrityError, message
      end

      if !mbox.exist?
        message = ".mbox file '#{mbox.pathname}' is missing"
        raise Serializer::FolderIntegrityError, message
      end

      if imap.messages.empty?
        if mbox.length.positive?
          message =
            ".imap file '#{imap.pathname}' lists no messages, " \
            "but .mbox file '#{mbox.pathname}' is not empty"
          raise Serializer::FolderIntegrityError, message
        end
        return
      end

      check_offset_ordering!
      check_mbox_length!
      check_message_starts!

      nil
    end

    private

    attr_reader :imap
    attr_reader :mbox

    def check_offset_ordering!
      offsets = imap.messages.map(&:offset)

      if offsets != offsets.sort
        message = ".imap file '#{imap.pathname}' has offset data which is out of order"
        raise Serializer::FolderIntegrityError, message
      end
    end

    def check_mbox_length!
      last = imap.messages[-1]

      expected = last.offset + last.length
      Logger.logger.debug(
        "[IntegrityChecker] mbox length is #{mbox.length}, expected length is #{expected}"
      )
      if mbox.length < expected
        message =
          ".mbox file '#{mbox.pathname}' is shorter than indicated by " \
          ".imap file '#{imap.pathname}'"
        raise Serializer::FolderIntegrityError, message
      end

      if mbox.length > expected
        message =
          ".mbox file '#{mbox.pathname}' is longer than indicated by " \
          ".imap file '#{imap.pathname}'"
        raise Serializer::FolderIntegrityError, message
      end
    end

    def check_message_starts!
      imap.messages.each do |m|
        text = mbox.read(m.offset, m.length)

        next if text.start_with?("From ")

        Logger.logger.debug(
          "[IntegrityChecker] looking for message with UID #{m.uid} " \
          "at offset #{m.offset}, " \
          "mbox starts with '#{text[0..200]}', expecting 'From '"
        )
        message =
          "Message #{m.uid} not found at expected offset #{m.offset} " \
          "in file '#{mbox.pathname}'"
        raise Serializer::FolderIntegrityError, message
      end
    end
  end
end
