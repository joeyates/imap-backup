require "email/provider"
require "retry_on_error"

module Imap::Backup
  class Account::Connection::ClientFactory
    include RetryOnError

    LOGIN_RETRY_CLASSES = [EOFError, Errno::ECONNRESET, SocketError].freeze

    attr_reader :account

    def initialize(account:)
      @account = account
      @provider = nil
      @server = nil
    end

    def run
      retry_on_error(errors: LOGIN_RETRY_CLASSES) do
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
        client.login
        client
      end
    end

    private

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
