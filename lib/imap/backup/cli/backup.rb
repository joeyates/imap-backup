module Imap::Backup
  class CLI::Backup < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :options

    def initialize(options)
      super([])
      @options = options
    end

    no_commands do
      def run
        config = load_config(**options)
        each_connection(config, emails) do |connection|
          connection.run_backup(refresh: refresh)
        rescue StandardError => e
          message =
            "Backup for account '#{connection.account.username}' " \
            "failed with error #{e}"
          Logger.logger.warn message
          next
        end
      end

      def emails
        (options[:accounts] || "").split(",")
      end

      def refresh
        options.key?(:refresh) ? !!options[:refresh] : false
      end
    end
  end
end
