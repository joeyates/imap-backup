require "imap/backup/serializer/files/path"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Finds a name that can be used to rename a serialized folder
  class Serializer::UnusedNameFinder
    # @param serializer [Serializer] a folder serializer
    def initialize(serializer:)
      @serializer = serializer
    end

    # Finds the name
    # @return [Serializer::Files::Path] the unused folder name
    def run
      digit = 0
      files_path = nil

      loop do
        extra = digit.zero? ? "" : "-#{digit}"
        folder = "#{serializer.files_path.folder_name}-#{serializer.uid_validity}#{extra}"
        files_path = Serializer::Files::Path.new(
          base_path: serializer.files_path.base_path,
          folder_name: folder
        )
        imap_path = "#{files_path}.imap"
        mbox_path = "#{files_path}.mbox"
        break if !File.exist?(imap_path) && !File.exist?(mbox_path)

        digit += 1
      end

      files_path
    end

    private

    attr_reader :serializer
  end
end
