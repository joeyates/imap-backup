module Imap::Backup
  class CLI::Remote < Thor
    include Thor::Actions
    include CLI::Helpers

    desc "folders EMAIL", "List account folders"
    config_option
    verbose_option
    quiet_option
    def folders(email)
      config = load_config(**symbolized(options))
      connection = connection(config, email)

      connection.folder_names.each do |name|
        Kernel.puts %("#{name}")
      end
    end
  end
end
