require "fileutils"

module Imap; end

module Imap::Backup
  class Serializer; end

  class Serializer::FolderMaker
    attr_reader :base
    attr_reader :path
    attr_reader :permissions

    def initialize(base:, path:, permissions:)
      @base = base
      @path = path
      @permissions = permissions
    end

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

    def full_path
      File.join(base, path)
    end
  end
end
