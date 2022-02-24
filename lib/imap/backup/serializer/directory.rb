require "os"

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
        Utils.make_folder(
          path, relative, DIRECTORY_PERMISSIONS
        )
      end

      if !OS.windows?
        if Utils.mode(full_path) != DIRECTORY_PERMISSIONS
          FileUtils.chmod DIRECTORY_PERMISSIONS, full_path
        end
      end
    end

    private

    def full_path
      containing_directory = File.join(path, relative)
      File.expand_path(containing_directory)
    end
  end
end
