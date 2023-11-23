require "fileutils"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Creates directories
  class Serializer::FolderMaker
    # @param base [String] The base directory of the account
    # @param path [String] The path to the folder, relative to the base
    # @param permissions [Integer] The permissions to set on the folder
    def initialize(base:, path:, permissions:)
      @base = base
      @path = path
      @permissions = permissions
    end

    # Creates the directory and any missing parent directories,
    # ensuring the desired permissions.
    # @return [void]
    def run
      parts = path.split("/")
      return if parts.empty?

      FileUtils.mkdir_p(full_path)
      full = base
      parts.each do |part|
        full = File.join(full, part)
        FileUtils.chmod permissions, full
      end
    end

    private

    attr_reader :base
    attr_reader :path
    attr_reader :permissions

    def full_path
      File.join(base, path)
    end
  end
end
