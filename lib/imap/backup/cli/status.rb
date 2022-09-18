module Imap::Backup
  class CLI::Status < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :emails

    def initialize(options)
      super([])
      @emails = (options[:accounts] || "").split(",")
    end

    no_commands do
      def run
        config = load_config
        each_connection(config, emails) do |connection|
          Kernel.puts connection.account.username
          folders = connection.status
          folders.each do |f|
            missing_locally = f[:remote] - f[:local]
            Kernel.puts "#{f[:name]}: #{missing_locally.size}"
          end
        end
      end
    end
  end
end
