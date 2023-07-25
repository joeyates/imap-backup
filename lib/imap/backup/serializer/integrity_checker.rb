module Imap; end

module Imap::Backup
  class Serializer; end

  class Serializer::FolderIntegrityError < StandardError; end

  class Serializer::IntegrityChecker
    attr_reader :imap
    attr_reader :mbox

    def initialize(imap:, mbox:)
      @imap = imap
      @mbox = mbox
    end

    def run
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

    def check_offset_ordering!
      offsets = imap.messages.map(&:offset)

      if offsets != offsets.sort
        message = ".imap file '#{imap.pathname}' has offset data which is out of order"
        raise Serializer::FolderIntegrityError, message
      end
    end

    def check_mbox_length!
      last = imap.messages[-1]

      if mbox.length < last.offset + last.length
        message =
          ".mbox file '#{mbox.pathname}' is shorter than indicated by " \
          ".imap file '#{imap.pathname}'"
        raise Serializer::FolderIntegrityError, message
      end

      if mbox.length > last.offset + last.length
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

        message =
          "Message #{m.uid} not found at expected offset #{m.offset} " \
          "in file '#{mbox.pathname}'"
        raise Serializer::FolderIntegrityError, message
      end
    end
  end
end
