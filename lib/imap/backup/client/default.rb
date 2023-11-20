require "forwardable"
require "net/imap"

require "imap/backup/logger"

module Imap; end

module Imap::Backup
  module Client; end

  # Wraps a Net::IMAP instance
  class Client::Default
    extend Forwardable
    def_delegators :imap, *%i(
      append authenticate capability create expunge namespace
      responses uid_fetch uid_search uid_store
    )

    def initialize(server, account, options)
      @account = account
      @options = options
      @server = server
      @state = nil
    end

    def list
      root = provider_root
      mailbox_lists = imap.list(root, "*")

      return [] if mailbox_lists.nil?

      mailbox_lists.map { |ml| extract_name(ml) }
    end

    def login
      Logger.logger.debug "Logging in: #{account.username}/#{masked_password}"
      imap.login(account.username, account.password)
      Logger.logger.debug "Login complete"
    end

    def reconnect
      disconnect
      login
    end

    def username
      account.username
    end

    # Track mailbox selection during delegation to Net::IMAP instance

    def disconnect
      imap.disconnect
      self.state = nil
    end

    def examine(mailbox)
      return if state == [:examine, mailbox]

      result = imap.examine(mailbox)
      self.state = [:examine, mailbox]
      result
    end

    def select(mailbox)
      return if state == [:select, mailbox]

      imap.select(mailbox)
      self.state = [:select, mailbox]
    end

    private

    attr_reader :account
    attr_reader :options
    attr_reader :server
    attr_accessor :state

    def imap
      @imap ||= Net::IMAP.new(server, options)
    end

    def extract_name(mailbox_list)
      utf7_encoded = mailbox_list.name
      Net::IMAP.decode_utf7(utf7_encoded)
    end

    def masked_password
      account.password.gsub(/./, "x")
    end

    # 6.3.8. LIST Command
    # An empty ("" string) mailbox name argument is a special request to
    # return the hierarchy delimiter and the root name of the name given
    # in the reference.
    def provider_root
      @provider_root ||= begin
        root_info = imap.list("", "")[0]
        root_info.name
      end
    end
  end
end
