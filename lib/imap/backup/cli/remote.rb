require "imap/backup/logger"

module Imap::Backup
  class CLI::Remote < Thor
    include Thor::Actions
    include CLI::Helpers

    desc "folders EMAIL", "List account folders"
    config_option
    verbose_option
    quiet_option
    def folders(email)
      Imap::Backup::Logger.setup_logging options
      config = load_config(**options)
      connection = connection(config, email)

      connection.folder_names.each do |name|
        Kernel.puts %("#{name}")
      end
    end
  end
end
