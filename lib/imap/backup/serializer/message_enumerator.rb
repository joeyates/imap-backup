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
      uids.each do |uid_maybe_string|
        uid = uid_maybe_string.to_i
        message = imap.get(uid)

        next if !message

        raw = mbox.read(message[:offset], message[:length])
        body = Email::Mboxrd::Message.from_serialized(raw)

        yield message[:uid], body, message[:flags]
      end
    end
  end
end
