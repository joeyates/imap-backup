require "imap/backup/email/provider"
require "imap/backup/setup/asker"

module Imap; end

module Imap::Backup
  class Setup; end

  class Setup::EmailChanger
    attr_reader :account
    attr_reader :config

    def initialize(account:, config:)
      @account = account
      @config = config
    end

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
