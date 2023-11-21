module Imap; end

module Imap::Backup
  # Enumerates over a list of stores messages
  class Serializer::MessageEnumerator
    attr_reader :imap

    # @param imap [Serializer::Imap] the metadata serializer for the folder
    def initialize(imap:)
      @imap = imap
    end

    # Enumerates over the messages
    # @param uids [Array<Integer>] the message UIDs of the messages to iterate over
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
