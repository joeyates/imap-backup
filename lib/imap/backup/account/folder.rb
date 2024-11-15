require "forwardable"
require "logger"
require "net/imap"

require "imap/backup/logger"
require "imap/backup/retry_on_error"

module Imap; end

module Imap::Backup
  class Account; end

  # Handles access to a folder on an IMAP server
  class Account::Folder
    # An error that is thrown if a requestd folder does not exist
    class FolderNotFound < StandardError; end

    extend Forwardable
    include RetryOnError

    # @return [Client::Default]
    attr_reader :client
    # @return [String] the name of the folder
    attr_reader :name

    def initialize(client, name)
      @client = client
      @name = name
      @uid_validity = nil
    end

    # @raise any error that occurs more than 10 times
    def exist?
      retry_on_error(errors: EXAMINE_RETRY_CLASSES) do
        examine
      end
      true
    rescue FolderNotFound
      false
    end

    # Creates the folder on the server
    # @return [void]
    def create
      return if exist?

      retry_on_error(errors: CREATE_RETRY_CLASSES) do
        client.create(utf7_encoded_name)
      end
    end

    # @raise any error that occurs more than 10 times
    # @return [Integer] the folder's UID validity
    def uid_validity
      @uid_validity ||=
        begin
          examine
          client.responses["UIDVALIDITY"][-1]
        end
    end

    # @raise any error that occurs more than 10 times
    # @return [Array<Integer>] the folders message UIDs
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
      Imap::Backup::Logger.logger.warn message
      []
    end

    # @raise any error that occurs more than 10 times
    # @return [Array<Hash>, nil] the requested messages
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

    # Uploads a message
    # @return [void]
    def append(message)
      body = message.imap_body
      date = message.date&.to_time
      flags = message.flags & PERMITTED_FLAGS
      retry_on_error(errors: APPEND_RETRY_CLASSES, limit: 3) do
        response = client.append(utf7_encoded_name, body, flags, date)
        extract_uid(response)
      end
    end

    # Deletes multiple messages
    # @return [void]
    def delete_multi(uids)
      add_flags(uids, [:Deleted])
      client.expunge
    end

    # Sets one or more flags on a group of messages
    # @return [void]
    def set_flags(uids, flags)
      client.select(utf7_encoded_name)
      flags.reject! { |f| f == :Recent }
      client.uid_store(uids, "FLAGS", flags)
    end

    # Adds one or more flags to a group of messages
    # @return [void]
    def add_flags(uids, flags)
      # Use read-write access, via `select`
      client.select(utf7_encoded_name)
      flags.reject! { |f| f == :Recent }
      client.uid_store(uids, "+FLAGS", flags)
    end

    # Removes one or more flags from a group of messages
    # @return [void]
    def remove_flags(uids, flags)
      client.select(utf7_encoded_name)
      client.uid_store(uids, "-FLAGS", flags)
    end

    # Deletes all messages from the folder
    # @return [void]
    def clear
      existing = uids
      return if existing.empty?

      add_flags(existing, [:Deleted])
      client.expunge
    end

    # @raise any error that occurs more than 10 times
    # @return [Array<Integer>] the UIDs of messages with the 'UNSEEN' flag
    def unseen(uids)
      messages = uids.map(&:to_s).join(",")
      examine
      client.uid_search(["UID", messages, "UNSEEN"])
    rescue NoMethodError
      # Apple Mail returns an empty response when searches have no results
      []
    rescue FolderNotFound
      nil
    end

    private

    BODY_ATTRIBUTE = "BODY[]".freeze
    UID_FETCH_RETRY_CLASSES = [::EOFError, ::Errno::ECONNRESET, ::IOError].freeze
    APPEND_RETRY_CLASSES = [::Net::IMAP::BadResponseError].freeze
    CREATE_RETRY_CLASSES = [::Net::IMAP::BadResponseError].freeze
    EXAMINE_RETRY_CLASSES = [::Net::IMAP::BadResponseError].freeze
    PERMITTED_FLAGS = %i(Answered Draft Flagged Seen).freeze

    def examine
      client.examine(utf7_encoded_name)
    rescue Net::IMAP::NoResponseError
      Imap::Backup::Logger.logger.warn "Folder '#{name}' does not exist on server"
      Imap::Backup::Logger.logger.warn caller.join("\n")
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
