module Imap; end

module Imap::Backup
  # Updates the flags on backed-up emails
  class FlagRefresher
    # The number of messages to process at a time
    CHUNK_SIZE = 100

    def initialize(folder, serializer)
      @folder = folder
      @serializer = serializer
    end

    # Runs the update
    # @return [void]
    def run
      uids = serializer.uids.clone

      uids.each_slice(CHUNK_SIZE) do |block|
        refresh_block block
      end
    end

    private

    attr_reader :folder
    attr_reader :serializer

    def refresh_block(uids)
      uids_and_flags = folder.fetch_multi(uids, ["FLAGS"])
      uids_and_flags.each do |uid_and_flags|
        uid = uid_and_flags[:uid]
        flags = uid_and_flags[:flags]
        serializer.update(uid, flags: flags)
      end
    end
  end
end
