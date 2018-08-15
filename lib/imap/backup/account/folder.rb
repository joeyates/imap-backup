require "forwardable"

module Imap::Backup
  module Account; end

  class Account::Folder
    extend Forwardable

    REQUESTED_ATTRIBUTES = ["RFC822", "FLAGS", "INTERNALDATE"].freeze

    attr_reader :connection
    attr_reader :name

    delegate imap: :connection

    def initialize(connection, name)
      @connection = connection
      @name = name
    end

    def folder
      name
    end

    def uids
      imap.examine(name)
      imap.uid_search(["ALL"]).sort
    rescue Net::IMAP::NoResponseError
      Imap::Backup.logger.warn "Folder '#{name}' does not exist"
      []
    end

    def fetch(uid)
      imap.examine(name)
      fetch_data_items = imap.uid_fetch([uid.to_i], REQUESTED_ATTRIBUTES)
      return nil if fetch_data_items.nil?
      fetch_data_item = fetch_data_items[0]
      attributes = fetch_data_item.attr
      attributes["RFC822"].force_encoding("utf-8")
      attributes
    rescue Net::IMAP::NoResponseError
      Imap::Backup.logger.warn "Folder '#{name}' does not exist"
      nil
    end
  end
end
