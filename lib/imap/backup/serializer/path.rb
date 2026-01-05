module Imap; end

module Imap::Backup
  class Serializer
    module Path
      module_function

      def from(path:, folder:)
        File.join(path, folder)
      end
    end
  end
end
