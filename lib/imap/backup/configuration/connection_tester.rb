# encoding: utf-8

module Imap::Backup
  module Configuration; end

  module Configuration::ConnectionTester
    def self.test(account)
      Account::Connection.new(account).imap
      return 'Connection successful'
    rescue Net::IMAP::NoResponseError
      return 'No response'
    rescue Exception => e
      return "Unexpected error: #{e}"
    end
  end
end
