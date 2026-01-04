require "os"

require "imap/backup/file_mode"
require "imap/backup/serializer/folder_maker"
require "imap/backup/serializer/path"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Ensures that serialization directories exist and have the correct permissions.
  class Serializer::Directory
    # The desired permissions for all directories that store backups
    DIRECTORY_PERMISSIONS = 0o700

    # @param path [String] The base path of the account backup
    # @param relative [String] The path relative from the base
    #
    # @return [void]
    def initialize(path, relative)
      @path = path
      @relative = relative
    end

    # Creates the directory, if present and sets it's access permissions
    #
    # @return [void]
    def ensure_exists
      if !File.directory?(full_path)
        Serializer::FolderMaker.new(
          base: path, path: relative, permissions: DIRECTORY_PERMISSIONS
        ).run
      end

      return if OS.windows?
      return if FileMode.new(filename: full_path).mode == DIRECTORY_PERMISSIONS

      FileUtils.chmod DIRECTORY_PERMISSIONS, full_path
    end

    private

    attr_reader :relative
    attr_reader :path

    def full_path
      Serializer::Path.from(path: path, folder: relative)
    end
  end
end
