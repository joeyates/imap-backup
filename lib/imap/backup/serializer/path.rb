module Imap; end

module Imap::Backup
  class Serializer
    module Path
      module_function

      def from(path:, folder:, expand: true)
        relative = File.join(path, folder)
        return relative if !expand

        File.expand_path(relative)
      end
    end
  end
end
