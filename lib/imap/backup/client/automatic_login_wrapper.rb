require "retry_on_error"

module Imap; end

module Imap::Backup
  module Client; end

  class Client::AutomaticLoginWrapper
    include RetryOnError

    LOGIN_RETRY_CLASSES = [::EOFError, ::Errno::ECONNRESET, ::SocketError].freeze

    attr_reader :client
    attr_reader :login_called

    def initialize(client:)
      @client = client
      @login_called = false
    end

    def method_missing(method_name, *arguments, &block)
      if login_called
        client.send(method_name, *arguments, &block)
      else
        do_first_login
        client.send(method_name, *arguments, &block) if method_name != :login
      end
    end

    def respond_to_missing?(method_name, _include_private = false)
      client.respond_to?(method_name)
    end

    private

    def do_first_login
      retry_on_error(errors: LOGIN_RETRY_CLASSES) do
        client.login
        @login_called = true
      end
    end
  end
end
