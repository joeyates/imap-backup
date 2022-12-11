require "forwardable"

require "retry_on_error"

module Imap::Backup
  class Account; end

  class FolderNotFound < StandardError; end

  class Account::Folder
    extend Forwardable
    include RetryOnError

    BODY_ATTRIBUTE = "BODY[]".freeze
    UID_FETCH_RETRY_CLASSES = [EOFError, Errno::ECONNRESET, IOError].freeze
    APPEND_RETRY_CLASSES = [Net::IMAP::BadResponseError].freeze
    PERMITTED_FLAGS = %i(Answered Draft Flagged Seen).freeze

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
      message =
        "Folder '#{name}' caused a NoMethodError. " \
        "Probably this was `undefined method `[]' for nil:NilClass (NoMethodError)` " \
        "in `search_internal` in stdlib net/imap.rb. " \
        'This is caused by `@responses["SEARCH"] being unset/undefined. ' \
        "Among others, Apple Mail servers send empty responses when " \
        "folders are empty, causing this error."
      Logger.logger.warn message
      []
    end

    def fetch_multi(uids, attr = [BODY_ATTRIBUTE, "FLAGS"])
      examine
      fetch_data_items =
        retry_on_error(errors: UID_FETCH_RETRY_CLASSES) do
          client.uid_fetch(uids, attr)
        end
      return nil if fetch_data_items.nil?

      fetch_data_items.map do |item|
        attributes = item.attr

        {
          uid: attributes["UID"],
          body: attributes[BODY_ATTRIBUTE],
          flags: attributes["FLAGS"]
        }
      end
    rescue FolderNotFound
      nil
    end

    def append(message)
      body = message.imap_body
      date = message.date&.to_time
      flags = message.flags & PERMITTED_FLAGS
      retry_on_error(errors: APPEND_RETRY_CLASSES, limit: 3) do
        response = client.append(utf7_encoded_name, body, flags, date)
        flags = message.flags & PERMITTED_FLAGS
        extract_uid(response)
      end
    end

    def delete_multi(uids)
      add_flags(uids, [:Deleted])
      client.expunge
    end

    def set_flags(uids, flags)
      client.select(utf7_encoded_name)
      flags.reject! { |f| f == :Recent }
      client.uid_store(uids, "FLAGS", flags)
    end

    def add_flags(uids, flags)
      # Use read-write access, via `select`
      client.select(utf7_encoded_name)
      flags.reject! { |f| f == :Recent }
      client.uid_store(uids, "+FLAGS", flags)
    end

    def remove_flags(uids, flags)
      client.select(utf7_encoded_name)
      client.uid_store(uids, "-FLAGS", flags)
    end

    def clear
      existing = uids
      return if existing.empty?

      add_flags(existing, [:Deleted])
      client.expunge
    end

    def unseen(uids)
      messages = uids.map(&:to_s).join(",")
      examine
      client.uid_search([messages, "UNSEEN"])
    rescue NoMethodError
      # Apple Mail returns an empty response when searches have no results
      []
    rescue FolderNotFound
      nil
    end

    private

    def examine
      client.examine(utf7_encoded_name)
    rescue Net::IMAP::NoResponseError
      Logger.logger.warn "Folder '#{name}' does not exist on server"
      raise FolderNotFound, "Folder '#{name}' does not exist on server"
    end

    def extract_uid(response)
      uid_data = response.data.code.data
      @uid_validity = uid_data.uidvalidity
      uid_data.assigned_uids.first
    end

    def utf7_encoded_name
      @utf7_encoded_name ||=
        Net::IMAP.encode_utf7(name).force_encoding("ASCII-8BIT")
    end
  end
end
