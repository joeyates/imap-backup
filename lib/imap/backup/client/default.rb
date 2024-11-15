require "forwardable"
require "net/imap"

require "imap/backup/logger"

module Imap; end

module Imap::Backup
  module Client; end

  # Wraps a Net::IMAP instance
  # Tracks the latest folder selection in order to avoid repeated calls
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

    # @return [Array<String>] the account folders
    def list
      root = provider_root
      Logger.logger.debug "Listing all account folders"
      mailbox_lists = imap.list(root, "*")

      return [] if mailbox_lists.nil?

      mailbox_lists.map { |ml| extract_name(ml) }
    end

    # Logs in to the account on the IMAP server
    # @return [void]
    def login
      Logger.logger.debug "Logging in: #{account.username}/#{masked_password}"
      imap.login(account.username, account.password)
      Logger.logger.debug "Login complete"
    end

    # Logs out and back in to the server
    # @return [void]
    def reconnect
      disconnect
      login
    end

    # @return [String] the account username
    def username
      account.username
    end

    # Disconects from the server
    # @return [void]
    def disconnect
      imap.disconnect
      self.state = nil
    end

    # Prepares read-only access to a folder
    # @return [void]
    def examine(mailbox)
      return if state == [:examine, mailbox]

      imap.examine(mailbox)
      self.state = [:examine, mailbox]
    end

    # Prepares read-write access to a folder
    # @return [void]
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
        Logger.logger.debug "Fetching provider root"
        root_info = imap.list("", "")[0]
        Logger.logger.debug "Provider root is '#{root_info.name}'"
        root_info.name
      end
    end
  end
end
