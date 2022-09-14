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
    end

    private

    def ensure_destination_folder
      return if folder.exist?

      folder.create
    end
  end
end
