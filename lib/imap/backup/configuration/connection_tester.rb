module Imap::Backup
  module Configuration; end

  module Configuration::ConnectionTester
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
