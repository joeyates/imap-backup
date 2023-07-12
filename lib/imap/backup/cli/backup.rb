require "imap/backup/account/backup"

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
        non_logging_options = Logger.setup_logging(options)
        config = load_config(**non_logging_options)
        requested_accounts(config).each do |account|
          backup = Account::Backup.new(account: account, refresh: refresh)
          backup.run
        rescue StandardError => e
          message =
            "Backup for account '#{account.username}' " \
            "failed with error #{e}"
          Logger.logger.warn message
          next
        end
      end

      def refresh
        options.key?(:refresh) ? !!options[:refresh] : false
      end
    end
  end
end
