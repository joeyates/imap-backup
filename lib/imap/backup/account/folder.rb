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
      @uid_validity = nil
    end

    # Deprecated: use #name
    def folder
      name
    end

    def exist?
      examine
      true
    rescue Net::IMAP::NoResponseError => e
      false
    end

    def create
      return if exist?
      imap.create(name)
    end

    def uid_validity
      @uid_validity ||=
        begin
          examine
          imap.responses["UIDVALIDITY"][-1]
        end
    end

    def uids
      examine
      imap.uid_search(["ALL"]).sort
    rescue Net::IMAP::NoResponseError
      Imap::Backup.logger.warn "Folder '#{name}' does not exist"
      []
    end

    def fetch(uid)
      examine
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

    def append(message)
      body = message.imap_body
      date = message.date.to_time
      response = imap.append(name, body, nil, date)
      extract_uid(response)
    end

    private

    def examine
      imap.examine(name)
    end

    def extract_uid(response)
      @uid_validity, uid = response.data.code.data.split(" ").map(&:to_i)
      uid
    end
  end
end
