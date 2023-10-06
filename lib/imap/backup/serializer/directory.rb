require "os"

require "imap/backup/file_mode"
require "imap/backup/serializer/folder_maker"

module Imap; end

module Imap::Backup
  class Serializer; end

  class Serializer::Directory
    DIRECTORY_PERMISSIONS = 0o700

    attr_reader :relative
    attr_reader :path

    def initialize(path, relative)
      @path = path
      @relative = relative
    end

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

    def full_path
      containing_directory = File.join(path, relative)
      File.expand_path(containing_directory)
    end
  end
end
