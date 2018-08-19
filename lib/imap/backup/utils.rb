require "fileutils"

module Imap::Backup
  module Utils
    def self.check_permissions(filename, limit)
      actual = mode(filename)
      return nil if actual.nil?
      mask = ~limit & 0o777
      if actual & mask != 0
        message = format(
          "Permissions on '%<filename>s' " \
            "should be 0%<limit>o, not 0%<actual>o",
          filename: filename, limit: limit, actual: actual
        )
        raise message
      end
    end

    def self.mode(filename)
      return nil if !File.exist?(filename)

      stat = File.stat(filename)
      stat.mode & 0o777
    end

    def self.make_folder(base_path, path, permissions)
      parts = path.split("/")
      return if parts.size == 0
      full_path = File.join(base_path, path)
      FileUtils.mkdir_p full_path
      path = base_path
      parts.each do |part|
        path = File.join(path, part)
        FileUtils.chmod permissions, path
      end
    end
  end
end
