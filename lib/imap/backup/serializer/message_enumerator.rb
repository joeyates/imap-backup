require "email/mboxrd/message"
require "imap/backup/serializer/mbox_enumerator"

module Imap::Backup
  class Serializer::MessageEnumerator
    attr_reader :imap
    attr_reader :mbox

    def initialize(imap:, mbox:)
      @imap = imap
      @mbox = mbox
    end

    def run(uids:)
      indexes = uids.each.with_object({}) do |uid_maybe_string, acc|
        uid = uid_maybe_string.to_i
        index = imap.index(uid)
        acc[index] = uid if index
      end
      enumerator = Serializer::MboxEnumerator.new(mbox.pathname)
      enumerator.each.with_index do |raw, i|
        uid = indexes[i]
        next if !uid

        yield uid, Email::Mboxrd::Message.from_serialized(raw)
      end
    end
  end
end
