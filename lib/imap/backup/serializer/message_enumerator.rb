module Imap; end

module Imap::Backup
  class Serializer; end

  # Enumerates over a list of stores messages
  class Serializer::MessageEnumerator
    # @param imap [Serializer::Imap] the metadata serializer for the folder
    def initialize(imap:)
      @imap = imap
    end

    # Enumerates over the messages
    # @param uids [Array<Integer>] the message UIDs of the messages to iterate over
    # @yieldparam message [Serializer::Message]
    # @return [void]
    def run(uids:, &block)
      uids.each do |uid_maybe_string|
        uid = uid_maybe_string.to_i
        message = imap.get(uid)

        next if !message

        block.call(message)
      end
    end

    private

    attr_reader :imap
  end
end
