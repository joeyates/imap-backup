require "imap/backup/email/provider"
require "imap/backup/setup/asker"

module Imap; end

module Imap::Backup
  class Setup; end

  # Asks the user for a new email address
  class Setup::EmailChanger
    # @param account [Account] an Account
    # @param config [Configuration] the application configuration
    def initialize(account:, config:)
      @account = account
      @config = config
    end

    # Asks the user for an email address,
    # ensuring that the supplied address is not an existing account
    # @return [void]
    def run
      username = Setup::Asker.email(account.username)
      other_accounts = config.accounts.reject { |a| a == account }
      others = other_accounts.map(&:username)
      if others.include?(username)
        Kernel.puts(
          "There is already an account set up with that email address"
        )
      else
        account.username = username
        if account.server.nil? || (account.server == "")
          default = default_server(username)
          account.server = default if default
        end
      end
    end

    private

    attr_reader :account
    attr_reader :config

    def default_server(username)
      provider = Email::Provider.for_address(username)

      if provider.is_a?(Email::Provider::Unknown)
        Kernel.puts "Can't decide provider for email address '#{username}'"
        return nil
      end

      provider.host
    end
  end
end
