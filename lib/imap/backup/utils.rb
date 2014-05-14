# encoding: utf-8
require 'fileutils'

module Imap::Backup
  module Utils
    def self.check_permissions(filename, limit)
      actual = stat(filename)
      return nil if actual.nil?
      mask = ~limit & 0777
      if actual & mask != 0
        raise format("Permissions on '%s' should be 0%o, not 0%o", filename, limit, actual)
      end
    end

    def self.stat(filename)
      return nil unless File.exist?(filename)

      stat = File.stat(filename)
      stat.mode & 0777
    end

    def self.make_folder(base_path, path, permissions)
      parts = path.split('/')
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
