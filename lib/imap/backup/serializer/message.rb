require "forwardable"

require "imap/backup/email/mboxrd/message"

module Imap; end

module Imap::Backup
  class Serializer::Message
    attr_accessor :flags
    attr_reader :length
    attr_reader :offset
    attr_accessor :uid

    extend Forwardable

    def_delegator :message, :supplied_body, :body
    def_delegators :message, :imap_body, :date, :subject

    def initialize(uid:, offset:, length:, mbox:, flags: [])
      @uid = uid
      @offset = offset
      @length = length
      @mbox = mbox
      @flags = flags.map(&:to_sym)
    end

    def to_h
      {
        uid: uid,
        offset: offset,
        length: length,
        flags: flags.map(&:to_s)
      }
    end

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
