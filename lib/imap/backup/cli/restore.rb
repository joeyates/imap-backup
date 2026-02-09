require "thor"

require "imap/backup/account/restore"
require "imap/backup/cli/helpers"
require "imap/backup/logger"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  # Restores backups for one or more accounts
  class CLI::Restore < Thor
    include Thor::Actions
    include CLI::Helpers

    # @param email [String, nil] optional email address identifying the account to restore
    # @param options [Hash] CLI options controlling output
    # @option opts [String] :config (nil) the path to the configuration file
    # @option opts [String] :erb_configuration (nil) the path to the ERB configuration file
    # @option opts [Array<String>] :accounts (nil) the accounts to restore
    # @option opts [String] :delimiter ("/") the destination folder delimiter
    # @option opts [String] :prefix ("") a prefix applied to restored folder names
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
          restore(account, **restore_options)
        when email && options.key?(:accounts)
          raise I18n.t("cli.restore.missing_email_parameter")
        when !email && options.key?(:accounts)
          Logger.logger.info(
            "Calling restore with the --account option is deprecated, " \
            "please pass a single EMAIL parameter"
          )
          requested_accounts(config).each { |a| restore(a) }
        else
          Logger.logger.info "Calling restore without an EMAIL parameter is deprecated"
          config.accounts.each { |a| restore(a) }
        end
      end
    end

    private

    attr_reader :email
    attr_reader :options

    def restore(account, **)
      restore = Account::Restore.new(account: account, **)
      restore.run
    end

    def restore_options
      options.slice(:delimiter, :prefix)
    end
  end
end
