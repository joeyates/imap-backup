# encoding: utf-8

module Imap
  module Backup
    module Serializer
      class Directory

        include Imap::Backup::Utils

        def initialize(path, folder)
          @path, @folder = path, folder
          check_permissions(path, 0700)
        end

        def uids
          return [] if ! File.exist?(directory)

          d = Dir.open(directory)
          d.map do |file|
            file[/^0*(\d+).json$/, 1]
          end.compact
        end

        private

        def directory
          File.join(@path, @folder)
        end

      end
    end
  end
end

