require "socket"

require "imap/backup/client/apple_mail"
require "imap/backup/client/automatic_login_wrapper"
require "imap/backup/client/default"
require "imap/backup/email/provider"

module Imap; end

module Imap::Backup
  class Account; end

  # Returns an IMAP client set up for the supplied account
  class Account::ClientFactory
    def initialize(account:)
      @account = account
      @provider = nil
      @server = nil
    end

    def run
      options = provider_options
      Logger.logger.debug(
        "Creating IMAP instance: #{server}, options: #{options.inspect}"
      )
      client =
        if provider.is_a?(Email::Provider::AppleMail)
          Client::AppleMail.new(server, account, options)
        else
          Client::Default.new(server, account, options)
        end
      Client::AutomaticLoginWrapper.new(client: client)
    end

    private

    attr_reader :account

    def provider
      @provider ||= Email::Provider.for_address(account.username)
    end

    def provider_options
      provider.options.merge(account.connection_options || {})
    end

    def server
      @server ||= account.server || provider.host
    end
  end
end
