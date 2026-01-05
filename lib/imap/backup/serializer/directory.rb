require "os"

require "imap/backup/file_mode"
require "imap/backup/serializer/folder_maker"
require "imap/backup/serializer/files/path"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Ensures that serialization directories exist and have the correct permissions.
  class Serializer::Directory
    # The desired permissions for all directories that store backups
    DIRECTORY_PERMISSIONS = 0o700

    # @param files_path [Serializer::Files::Path] path components for the directory
    #
    # @return [void]
    def initialize(files_path:)
      @files_path = files_path
    end

    # Creates the directory, if present and sets it's access permissions
    #
    # @return [void]
    def ensure_exists
      full_path = files_path.to_s
      if !File.directory?(full_path)
        Serializer::FolderMaker.new(
          files_path: files_path, permissions: DIRECTORY_PERMISSIONS
        ).run
      end

      return if OS.windows?
      return if FileMode.new(filename: full_path).mode == DIRECTORY_PERMISSIONS

      FileUtils.chmod DIRECTORY_PERMISSIONS, full_path
    end

    private

    attr_reader :files_path
  end
end
