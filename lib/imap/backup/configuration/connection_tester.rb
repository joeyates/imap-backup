# encoding: utf-8

module Imap
  module Backup
    module Configuration
      module ConnectionTester
        def self.test(account)
          Imap::Backup::Account::Connection.new(account)
          return 'Connection successful'
        rescue Net::IMAP::NoResponseError
          return 'No response'
        rescue Exception => e
          return "Unexpected error: #{e}"
        end
      end
    end
  end
end

