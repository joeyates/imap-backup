module Imap::Backup
  class CLI::Folders < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :emails
    attr_reader :options

    def initialize(options)
      super([])
      @options = options
    end

    no_commands do
      def run
        config = load_config(**options)
        each_connection(config, emails) do |connection|
          Kernel.puts connection.account.username
          # TODO: Make folder_names private once this command
          # has been removed.
          folders = connection.folder_names
          if folders.nil?
            Kernel.warn "Unable to list account folders"
            return false
          end
          folders.each { |f| Kernel.puts "\t#{f}" }
        end
      end

      def emails
        (options[:accounts] || "").split(",")
      end
    end
  end
end
