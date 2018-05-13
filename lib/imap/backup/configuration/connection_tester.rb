module Imap::Backup
  module Configuration; end

  module Configuration::ConnectionTester
    def self.test(account)
      Account::Connection.new(account).imap
      "Connection successful"
    rescue Net::IMAP::NoResponseError
      "No response"
    rescue Exception => e
      "Unexpected error: #{e}"
    end
  end
end
