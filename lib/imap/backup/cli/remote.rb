module Imap::Backup
  class CLI::Remote < Thor
    include Thor::Actions
    include CLI::Helpers

    desc "folders EMAIL", "List account folders"
    def folders(email)
      connection = connection(email)

      connection.folder_names.each do |name|
        Kernel.puts %("#{name}")
      end
    end
  end
end
