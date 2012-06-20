# encoding: utf-8
require 'fileutils'

module Imap
  module Backup
    module Utils

      def self.check_permissions(filename, limit)
        actual = stat(filename)
        mask   = ~limit & 0777
        if actual & mask != 0
          raise "Permissions on '#{filename}' should be #{oct(limit)}, not #{oct(actual)}" 
        end
      end

      def self.stat(filename)
        return nil unless File.exist?(filename)

        stat   = File.stat(filename)
        stat.mode & 0777
      end

      def self.make_folder(base_path, path, permissions)
        parts = path.split('/')
        return if parts.size == 0
        full_path = File.join(base_path, path)
        FileUtils.mkdir_p full_path
        first_directory = File.join(base_path, parts[0])
        FileUtils.chmod permissions, first_directory
      end

      private

      def self.oct(permissions)
        "0%o" % permissions
      end

    end
  end
end

