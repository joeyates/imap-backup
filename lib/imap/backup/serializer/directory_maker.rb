require "fileutils"
require "os"

require "imap/backup/serializer/files/path"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Creates any directories needed to store backups
  class Serializer::DirectoryMaker
    # @param files_path [Serializer::Files::Path] the folder path components
    # @param permissions [Integer] The permissions to set on the folder
    def initialize(files_path:)
      @files_path = files_path
    end

    # Creates the containing directory and any missing parent directories,
    # ensuring the required permissions (except on Windows).
    # @return [void]
    def run
      directory = files_path.directory
      FileUtils.mkdir_p(directory)

      return if windows?

      FileUtils.chmod DIRECTORY_PERMISSIONS, directory
    end

    private

    attr_reader :files_path

    # The desired permissions for all directories that store backups
    DIRECTORY_PERMISSIONS = 0o700
    private_constant :DIRECTORY_PERMISSIONS

    def windows?
      OS.windows?
    end
  end
end
