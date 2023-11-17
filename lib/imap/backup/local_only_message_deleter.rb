require "imap/backup/logger"

module Imap; end

module Imap::Backup
  class LocalOnlyMessageDeleter
    def initialize(folder, serializer)
      @folder = folder
      @serializer = serializer
    end

    # TODO: this method is very slow as it copies all messages.
    # A quicker method would only remove UIDs from the .imap file,
    # but that would require a garbage collection later.
    def run
      local_only_uids = serializer.uids - folder.uids
      if local_only_uids.empty?
        Logger.logger.debug "There are no 'local-only' messages to delete"
        return
      end

      Logger.logger.info "Deleting messages only present locally"
      Logger.logger.debug "Messages to be deleted: #{local_only_uids.inspect}"

      serializer.filter do |message|
        !local_only_uids.include?(message.uid)
      end
    end

    private

    attr_reader :folder
    attr_reader :serializer
  end
end
