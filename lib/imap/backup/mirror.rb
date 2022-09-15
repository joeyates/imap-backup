require "imap/backup/mirror/map"

module Imap::Backup
  class Mirror
    attr_reader :serializer
    attr_reader :folder

    def initialize(serializer, folder)
      @serializer = serializer
      @folder = folder
    end

    def run
      ensure_destination_folder
      delete_destination_only_emails
    end

    private

    def ensure_destination_folder
      return if folder.exist?

      folder.create
    end

    def delete_destination_only_emails
      uids_to_delete = destination_only_emails
      return if uids_to_delete.empty?

      folder.delete_multi(uids_to_delete)
    end

    def destination_only_emails
      folder.uids
    end
  end
end
