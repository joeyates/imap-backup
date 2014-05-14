# encoding: utf-8

module Imap::Backup
  module Serializer
    DIRECTORY_PERMISSIONS = 0700
    FILE_PERMISSIONS      = 0600

    class Base
      def initialize(path, folder)
        @path, @folder = path, folder
        Utils.check_permissions(@path, DIRECTORY_PERMISSIONS)
      end
    end
  end
end
