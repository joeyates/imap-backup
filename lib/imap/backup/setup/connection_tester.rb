module Imap::Backup
  class Setup; end

  class Setup::ConnectionTester
    attr_reader :account

    def initialize(account)
      @account = account
    end

    def test
      connection.client
      "Connection successful"
    rescue Net::IMAP::NoResponseError
      "No response"
    rescue StandardError => e
      "Unexpected error: #{e}"
    end

    private

    def connection
      Account::Connection.new(account)
    end
  end
end
