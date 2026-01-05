require "fileutils"
require "imap/backup/serializer/files/path"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Creates directories
  class Serializer::FolderMaker
    # @param files_path [Serializer::Files::Path] the folder path components
    # @param permissions [Integer] The permissions to set on the folder
    def initialize(files_path:, permissions:)
      @files_path = files_path
      @permissions = permissions
    end

    # Creates the directory and any missing parent directories,
    # ensuring the desired permissions.
    # @return [void]
    def run
      parts = files_path.folder_name.split("/")
      return if parts.empty?

      FileUtils.mkdir_p(files_path.to_s)
      full = files_path.base_path
      parts.each do |part|
        full = File.join(full, part)
        FileUtils.chmod permissions, full
      end
    end

    private

    attr_reader :files_path
    attr_reader :permissions
  end
end
