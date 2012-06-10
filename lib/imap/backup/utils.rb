require 'fileutils'

module Imap
  module Backup
    module Utils

      def check_permissions(filename, limit)
        stat   = File.stat(filename)
        actual = stat.mode & 0777
        mask   = ~limit & 0777
        if actual & mask != 0
          raise "Permissions on '#{filename}' should be #{oct(limit)}, not #{oct(actual)}" 
        end
      end

      def make_folder(base_path, path, permissions)
        parts = path.split('/')
        return if parts.size == 0
        full_path = File.join(base_path, path)
        FileUtils.mkdir_p(full_path)
        first_directory = File.join(base_path, parts[0])
        FileUtils.chmod_R(permissions, first_directory)
      end

      private

      def oct(permissions)
        "0%o" % permissions
      end

    end
  end
end

