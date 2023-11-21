module Imap; end

module Imap::Backup
  # Enumerates over a list of stores messages
  class Serializer::MessageEnumerator
    attr_reader :imap

    def initialize(imap:)
      @imap = imap
    end

    # Enumerates over the messages
    def run(uids:)
      uids.each do |uid_maybe_string|
        uid = uid_maybe_string.to_i
        message = imap.get(uid)

        next if !message

        yield message
      end
    end
  end
end
