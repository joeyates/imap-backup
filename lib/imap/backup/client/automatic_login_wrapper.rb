require "imap/backup/retry_on_error"

module Imap; end

module Imap::Backup
  module Client; end

  # Transparently wraps a client instance, while delaying login until it becomes necessary
  class Client::AutomaticLoginWrapper
    include RetryOnError

    # @private
    LOGIN_RETRY_CLASSES = [::EOFError, ::Errno::ECONNRESET, ::SocketError].freeze

    # @return [Client]
    attr_reader :client

    def initialize(client:)
      @client = client
      @login_called = false
    end

    # Proxies calls to the client.
    # Before the first call does login
    # @return the return value of the client method called
    def method_missing(method_name, *arguments, &block)
      if login_called
        client.send(method_name, *arguments, &block)
      else
        do_first_login
        client.send(method_name, *arguments, &block) if method_name != :login
      end
    end

    # @return [Boolean] whether the client responds to the method
    def respond_to_missing?(method_name, _include_private = false)
      client.respond_to?(method_name)
    end

    private

    attr_reader :login_called

    def do_first_login
      retry_on_error(errors: LOGIN_RETRY_CLASSES) do
        client.login
        @login_called = true
      end
    end
  end
end
