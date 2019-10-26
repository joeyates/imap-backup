require "forwardable"

module Imap::Backup
  module Account; end

  class FolderNotFound < StandardError; end

  class Account::Folder
    extend Forwardable

    REQUESTED_ATTRIBUTES = %w[RFC822 FLAGS INTERNALDATE].freeze

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
    rescue FolderNotFound
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
    rescue FolderNotFound
      []
    rescue NoMethodError
      message = <<~MESSAGE
        Folder '#{name}' caused NoMethodError
        probably
        `undefined method `[]' for nil:NilClass (NoMethodError)`
        in `search_internal` in stdlib net/imap.rb.
        This is caused by `@responses["SEARCH"] being unset/undefined
      MESSAGE
      Imap::Backup.logger.warn message
      []
    end

    def fetch(uid)
      examine
      fetch_data_items = imap.uid_fetch([uid.to_i], REQUESTED_ATTRIBUTES)
      return nil if fetch_data_items.nil?

      fetch_data_item = fetch_data_items[0]
      attributes = fetch_data_item.attr
      return nil if !attributes.key?("RFC822")

      attributes
    rescue FolderNotFound
      nil
    end

    def append(message)
      body = message.imap_body
      date = message.date&.to_time
      response = imap.append(name, body, nil, date)
      extract_uid(response)
    end

    private

    def examine
      imap.examine(name)
    rescue Net::IMAP::NoResponseError
      Imap::Backup.logger.warn "Folder '#{name}' does not exist"
      raise FolderNotFound, "Folder '#{name}' does not exist"
    end

    def extract_uid(response)
      @uid_validity, uid = response.data.code.data.split(" ").map(&:to_i)
      uid
    end
  end
end
