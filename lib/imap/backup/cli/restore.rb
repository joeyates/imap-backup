require "thor"

require "imap/backup/cli/helpers"
require "imap/backup/logger"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  # Restores backups for one or more accounts
  class CLI::Restore < Thor
    include Thor::Actions
    include CLI::Helpers

    def initialize(email = nil, options)
      super([])
      @email = email
      @options = options
    end

    # @!method run
    #   @raise [RuntimeError] if no email is specified
    #   @return [void]
    no_commands do
      def run
        config = load_config(**options)
        case
        when email && !options.key?(:accounts)
          account = account(config, email)
          account.restore
        when !email && !options.key?(:accounts)
          Logger.logger.info "Calling restore without an EMAIL parameter is deprecated"
          config.accounts.map(&:restore)
        when email && options.key?(:accounts)
          raise "Missing EMAIL parameter"
        when !email && options.key?(:accounts)
          Logger.logger.info(
            "Calling restore with the --account option is deprected, " \
            "please pass a single EMAIL parameter"
          )
          requested_accounts(config).each(&:restore)
        end
      end
    end

    private

    attr_reader :email
    attr_reader :options
  end
end
