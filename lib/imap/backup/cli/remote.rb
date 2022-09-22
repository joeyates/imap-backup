require "imap/backup/logger"

module Imap::Backup
  class CLI::Remote < Thor
    include Thor::Actions
    include CLI::Helpers

    desc "folders EMAIL", "List account folders"
    config_option
    format_option
    quiet_option
    verbose_option
    def folders(email)
      Imap::Backup::Logger.setup_logging options
      names = names(email)
      case options[:format]
      when "json"
        json_format_names names
      else
        list_names names
      end
    end

    no_commands do
      def names(email)
        config = load_config(**options)
        connection = connection(config, email)

        connection.folder_names
      end

      def json_format_names(names)
        list = names.map do |name|
          {name: name}
        end
        Kernel.puts list.to_json
      end

      def list_names(names)
        names.each do |name|
          Kernel.puts %("#{name}")
        end
      end
    end
  end
end
