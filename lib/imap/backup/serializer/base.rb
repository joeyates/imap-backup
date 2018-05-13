module Imap::Backup
  module Serializer
    DIRECTORY_PERMISSIONS = 0700
    FILE_PERMISSIONS      = 0600

    class Base
      attr_reader :path
      attr_reader :folder

      def initialize(path, folder)
        @path, @folder = path, folder
        Utils.check_permissions(@path, DIRECTORY_PERMISSIONS)
      end
    end
  end
end
