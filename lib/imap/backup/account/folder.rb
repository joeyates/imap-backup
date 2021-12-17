require "forwardable"

require "retry_on_error"

module Imap::Backup
  module Account; end

  class FolderNotFound < StandardError; end

  class Account::Folder
    extend Forwardable
    include RetryOnError

    BODY_ATTRIBUTE = "BODY[]".freeze
    UID_FETCH_RETRY_CLASSES = [EOFError].freeze

    attr_reader :connection
    attr_reader :name

    delegate client: :connection

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

      client.create(utf7_encoded_name)
    end

    def uid_validity
      @uid_validity ||=
        begin
          examine
          client.responses["UIDVALIDITY"][-1]
        end
    end

    def uids
      examine
      client.uid_search(["ALL"]).sort
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
      fetch_data_items =
        retry_on_error(errors: UID_FETCH_RETRY_CLASSES) do
          client.uid_fetch([uid.to_i], [BODY_ATTRIBUTE])
        end
      return nil if fetch_data_items.nil?

      fetch_data_item = fetch_data_items[0]
      attributes = fetch_data_item.attr

      attributes[BODY_ATTRIBUTE]
    rescue FolderNotFound
      nil
    end

    def append(message)
      body = message.imap_body
      date = message.date&.to_time
      response = client.append(utf7_encoded_name, body, nil, date)
      extract_uid(response)
    end

    private

    def examine
      client.examine(utf7_encoded_name)
    rescue Net::IMAP::NoResponseError
      Imap::Backup.logger.warn "Folder '#{name}' does not exist on server"
      raise FolderNotFound, "Folder '#{name}' does not exist on server"
    end

    def extract_uid(response)
      @uid_validity, uid = response.data.code.data.split(" ").map(&:to_i)
      uid
    end

    def utf7_encoded_name
      @utf7_encoded_name ||=
        Net::IMAP.encode_utf7(name).force_encoding("ASCII-8BIT")
    end
  end
end
