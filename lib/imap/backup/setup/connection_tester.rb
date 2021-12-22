module Imap::Backup
  class Setup; end

  module Setup::ConnectionTester
    def self.test(account)
      Account::Connection.new(account).client
      "Connection successful"
    rescue Net::IMAP::NoResponseError
      "No response"
    rescue StandardError => e
      "Unexpected error: #{e}"
    end
  end
end
