require "socket"

require "imap/backup/client/automatic_login_wrapper"
require "imap/backup/client/default"

module Imap; end

module Imap::Backup
  class Account; end

  # Returns an IMAP client set up for the supplied account
  class Account::ClientFactory
    def initialize(account:)
      @account = account
    end

    # @return [Client::AutomaticLoginWrapper] a client for the account
    def run
      Logger.logger.debug("Creating IMAP instance")
      client = Client::Default.new(account)
      Client::AutomaticLoginWrapper.new(client: client)
    end

    private

    attr_reader :account
  end
end
