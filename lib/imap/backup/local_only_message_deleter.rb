module Imap::Backup
  class LocalOnlyMessageDeleter
    attr_reader :folder
    attr_reader :serializer

    def initialize(folder, serializer, multi_fetch_size: 1, reset_seen_flags_after_fetch: false)
      @folder = folder
      @serializer = serializer
    end

    # TODO: this method is very slow as it copies all messages.
    # A quicker method would only remove UIDs from the .imap file,
    # but that would require a garbage collection later.
    def run
      local_only_uids = serializer.uids - folder.uids
      return if local_only_uids.empty?

      serializer.filter do |message|
        !local_only_uids.include?(message.uid)
      end
    end
  end
end
