require "imap/backup/account/backup"

module Imap; end

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
        requested_accounts(config).each do |account|
          backup = Account::Backup.new(account: account, refresh: refresh)
          backup.run
        rescue StandardError => e
          message = <<~ERROR
            Backup for account '#{account.username}' failed with error #{e}
            #{e.backtrace.join("\n")}
          ERROR
          Logger.logger.error message
          next
        end
      end

      def refresh
        options.key?(:refresh) ? !!options[:refresh] : false
      end
    end
  end
end
