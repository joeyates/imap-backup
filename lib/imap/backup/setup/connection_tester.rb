require "net/imap"

module Imap; end

module Imap::Backup
  class Setup; end

  # Attempts to login to an account and reports the result
  class Setup::ConnectionTester
    # @param account [Account] an Account
    def initialize(account)
      @account = account
    end

    # Carries out the attempted login and indicates
    # whether it was successful
    # @return [void]
    def test
      account.client.login
      "Connection successful"
    rescue Net::IMAP::NoResponseError
      "No response"
    rescue StandardError => e
      "Unexpected error: #{e}"
    end

    private

    attr_reader :account
  end
end
