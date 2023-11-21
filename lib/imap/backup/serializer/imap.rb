require "json"

require "imap/backup/serializer/message"
require "imap/backup/serializer/mbox"
require "imap/backup/serializer/transaction"

module Imap; end

module Imap::Backup
  # Stores message metadata
  class Serializer::Imap
    # The version number to store in the metadata file
    CURRENT_VERSION = 3

    attr_reader :folder_path

    # @param folder_path [String] The path of the imap metadata file, without the '.imap' extension
    def initialize(folder_path)
      @folder_path = folder_path
      @loaded = false
      @uid_validity = nil
      @messages = nil
      @version = nil
      @tsx = nil
    end

    # Opens a transaction
    # @param block [block] the block that is wrapped by the transaction
    def transaction(&block)
      tsx.fail_in_transaction!(:transaction, message: "nested transactions are not supported")

      ensure_loaded
      # rubocop:disable Lint/RescueException
      tsx.begin({savepoint: {messages: messages.dup, uid_validity: uid_validity}}) do
        block.call

        save_internal(version: version, uid_validity: uid_validity, messages: messages) if tsx.data
      rescue Exception => e
        Logger.logger.error "#{self.class} handling #{e.class}"
        rollback
        raise e
      end
      # rubocop:enable Lint/RescueException
    end

    # Discards stored changes to the data
    def rollback
      tsx.fail_outside_transaction!(:rollback)

      @messages = tsx.data[:savepoint][:messages]
      @uid_validity = tsx.data[:savepoint][:uid_validity]

      tsx.clear
    end

    # @return [String] The full path name of the metadata file
    def pathname
      "#{folder_path}.imap"
    end

    def exist?
      File.exist?(pathname)
    end

    def valid?
      return false if !exist?
      return false if version != CURRENT_VERSION
      return false if !uid_validity

      true
    end

    # Append message metadata
    # @param uid [Integer] the message's UID
    # @param length [Integer] the length of the message (as stored on disk)
    # @param flags [Array[Symbol]] the message's flags
    def append(uid, length, flags: [])
      offset =
        if messages.empty?
          0
        else
          last_message = messages[-1]
          last_message.offset + last_message.length
        end

      messages << Serializer::Message.new(
        uid: uid, offset: offset, length: length, mbox: mbox, flags: flags
      )

      save
    end

    # Get message metadata
    # @param uid [Integer] a message UID
    def get(uid)
      messages.find { |m| m.uid == uid }
    end

    # Deletes the metadata file
    # and discards stored attributes
    def delete
      return if !exist?

      FileUtils.rm(pathname)
      @loaded = false
      @messages = nil
      @uid_validity = nil
      @version = nil
    end

    # Renames the metadata file, if it exists,
    # otherwise, simply stores the new name
    # @param new_path [String] the new path (without extension)
    def rename(new_path)
      if exist?
        old_pathname = pathname
        @folder_path = new_path
        File.rename(old_pathname, pathname)
      else
        @folder_path = new_path
      end
    end

    # Returns the UID validity for the folder
    def uid_validity
      ensure_loaded
      @uid_validity
    end

    # Sets the folder's UID validity and saves the metadata file
    # @param value [Integer] the new UID validity
    def uid_validity=(value)
      ensure_loaded
      @uid_validity = value
      save
    end

    # TODO: Make private
    def messages
      ensure_loaded
      @messages
    end

    # @return [Array<Integer>] The uids of all messages
    def uids
      messages.map(&:uid)
    end

    # Update a message's metadata, replacing its UID
    # @param old [Integer] the existing message UID
    # @param new [Integer] the new UID to apply to the message
    def update_uid(old, new)
      index = messages.find_index { |m| m.uid == old }
      return if index.nil?

      messages[index].uid = new
      save
    end

    # @return [String] The format version for the metadata file
    def version
      ensure_loaded
      @version
    end

    # Saves the file,
    # except in a transaction when it does nothing
    def save
      return if tsx.in_transaction?

      ensure_loaded

      save_internal(version: version, uid_validity: uid_validity, messages: messages)
    end

    private

    attr_reader :loaded

    def save_internal(version:, uid_validity:, messages:)
      raise "Cannot save metadata without a uid_validity" if !uid_validity

      data = {
        version: version,
        uid_validity: uid_validity,
        messages: messages.map(&:to_h)
      }
      content = data.to_json
      File.open(pathname, "w") { |f| f.write content }
    end

    def ensure_loaded
      return if loaded

      data = load
      if data
        @messages = data[:messages].map { |m| Serializer::Message.new(mbox: mbox, **m) }
        @uid_validity = data[:uid_validity]
        @version = data[:version]
      else
        @messages = []
        @uid_validity = nil
        @version = CURRENT_VERSION
      end
      @loaded = true
    end

    def load
      return nil if !exist?

      data = nil
      begin
        content = File.read(pathname)
        data = JSON.parse(content, symbolize_names: true)
      rescue JSON::ParserError
        return nil
      end

      return nil if !data.key?(:version)
      return nil if !data.key?(:uid_validity)
      return nil if !data.key?(:messages)
      return nil if !data[:messages].is_a?(Array)

      data
    end

    def mbox
      @mbox ||= Serializer::Mbox.new(folder_path)
    end

    def tsx
      @tsx ||= Serializer::Transaction.new(owner: self)
    end
  end
end
