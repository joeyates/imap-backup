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

    # @param options [Hash] CLI options controlling output
    # @option opts [String] :config (nil) the path to the configuration file
    # @option opts [String] :erb_configuration (nil) the path to the ERB configuration file
    # @option opts [Boolean] :refresh (false) whether to force refresh of folder metadata
    def initialize(options)
      super([])
      @options = options
    end

    # @!method run
    #   @return [void]
    no_commands do
      def run
        Logger.logger.debug "Loading configuration"
        config = load_config(**options)
        exit_code = nil
        accounts = requested_accounts(config)
        # Filter to only include accounts available for backup
        accounts = accounts.select(&:available_for_backup?)
        if accounts.none?
          Logger.logger.warn "No matching accounts found to backup"
          return
        end
        Logger.logger.debug "Starting backup of #{accounts.count} accounts"
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
        Logger.logger.debug "Backup complete"
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
      when Lockfile::LockfileExistsError
        112
      else
        1
      end
    end
  end
end
