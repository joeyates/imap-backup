require "net/imap"
require "thor"

require "imap/backup/account/backup"
require "imap/backup/cli/helpers"
require "imap/backup/logger"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  # Runs backups of configured accounts
  class CLI::Backup < Thor
    include Thor::Actions
    include CLI::Helpers

    def initialize(options)
      super([])
      @options = options
    end

    # @!method run
    #   @return [void]
    no_commands do
      def run
        config = load_config(**options)
        exit_code = nil
        accounts = requested_accounts(config)
        if accounts.none?
          Logger.logger.warn "No matching accounts found to backup"
          return
        end
        accounts.each do |account|
          backup = Account::Backup.new(account: account, refresh: refresh)
          backup.run
        rescue StandardError => e
          exit_code ||= choose_exit_code(e)
          message = <<~ERROR
            Backup for account '#{account.username}' failed with error #{e}
            #{e.backtrace.join("\n")}
          ERROR
          Logger.logger.error message
          next
        end
        exit(exit_code) if exit_code
      end
    end

    private

    attr_reader :options

    def refresh
      options.key?(:refresh) ? !!options[:refresh] : false
    end

    def choose_exit_code(exception)
      case exception
      when Net::IMAP::NoResponseError, Errno::ECONNREFUSED
        111
      else
        1
      end
    end
  end
end
