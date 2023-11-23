require "forwardable"

require "imap/backup/email/mboxrd/message"

module Imap; end

module Imap::Backup
  # Represents a stored message
  class Serializer::Message
    # @return [Array[Symbol]] the message's flags
    attr_accessor :flags
    # @return [Integer] the length of the message (as stored on disk)
    attr_reader :length
    # @return [Integer] the start of the message inside the mailbox file
    attr_reader :offset
    # @return [Integer] the message's UID
    attr_accessor :uid

    extend Forwardable

    def_delegator :message, :supplied_body, :body
    def_delegators :message, :imap_body, :date, :subject

    # @param uid [Integer] the message's UID
    # @param offset [Integer] the start of the message inside the mailbox file
    # @param length [Integer] the length of the message (as stored on disk)
    # @param mbox [Serializer::Mbox] the mailbox containing the message
    # @param flags [Array[Symbol]] the message's flags
    def initialize(uid:, offset:, length:, mbox:, flags: [])
      @uid = uid
      @offset = offset
      @length = length
      @mbox = mbox
      @flags = flags.map(&:to_sym)
    end

    # @return [Hash] the message metadata
    def to_h
      {
        uid: uid,
        offset: offset,
        length: length,
        flags: flags.map(&:to_s)
      }
    end

    # Reads the message text and returns the original form
    # @return [String] the message
    def message
      @message =
        begin
          raw = mbox.read(offset, length)
          Email::Mboxrd::Message.from_serialized(raw)
        end
    end

    private

    attr_reader :mbox
  end
end
