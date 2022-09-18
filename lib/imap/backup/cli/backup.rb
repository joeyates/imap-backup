module Imap::Backup
  class CLI::Backup < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :emails
    attr_reader :refresh

    def initialize(options)
      super([])
      @emails = (options[:accounts] || "").split(",")
      @refresh = options.key?(:refresh) ? !!options[:refresh] : false
    end

    no_commands do
      def run
        each_connection(config, emails) do |connection|
          connection.run_backup(refresh: refresh)
        end
      end
    end
  end
end
