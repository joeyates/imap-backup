require "json"

require "imap/backup/serializer/message"
require "imap/backup/serializer/mbox"
require "imap/backup/serializer/transaction"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Stores message metadata
  class Serializer::Imap
    # The version number to store in the metadata file
    CURRENT_VERSION = 3.1

    LOADABLE_VERSIONS = [3, 3.1].freeze

    # @return [Serializer::Files::Path] The path of the imap metadata file, without the '.imap'
    #   extension
    attr_reader :files_path

    # @param files_path [Serializer::Files::Path] The path of the imap metadata file, without
    #   the '.imap' extension
    def initialize(files_path:)
      @files_path = files_path
      @loaded = false
      @uid_validity = nil
      @messages = nil
      @version = nil
      @tsx = nil
    end

    # Opens a transaction
    # @param block [block] the block that is wrapped by the transaction
    # @raise any exception ocurring in the block
    # @return [void]
    def transaction(&block)
      tsx.fail_in_transaction!(:transaction, message: "nested transactions are not supported")

      ensure_loaded
      # rubocop:disable Lint/RescueException
      tsx.begin({savepoint: {messages: messages.dup, uid_validity: uid_validity}}) do
        block.call

        if tsx.data
          save_internal(version: CURRENT_VERSION, uid_validity: uid_validity, messages: messages)
        end
      rescue Exception => e
        Logger.logger.error "#{self.class} handling #{e.class}"
        rollback
        raise e
      end
      # rubocop:enable Lint/RescueException
    end

    # Discards stored changes to the data
    # @return [void]
    def rollback
      tsx.fail_outside_transaction!(:rollback)

      @messages = tsx.data[:savepoint][:messages]
      @uid_validity = tsx.data[:savepoint][:uid_validity]

      tsx.clear
    end

    # @return [String] The full path name of the metadata file
    def pathname
      "#{files_path}.imap"
    end

    def exist?
      File.exist?(pathname)
    end

    def valid?
      return false if !exist?
      return false if !loadable_version?(version)
      return false if !uid_validity

      true
    end

    # Append message metadata
    # @param uid [Integer] the message's UID
    # @param length [Integer] the length of the message (as stored on disk)
    # @param flags [Array[Symbol]] the message's flags
    # @return [void]
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

    # Updates a message's length and/or flags
    # @param uid [Integer] the existing message's UID
    # @param length [Integer] the length of the message (as stored on disk)
    # @param flags [Array[Symbol]] the message's flags
    # @raise [RuntimeError] if the UID does not exist
    # @return [void]
    def update(uid, length: nil, flags: nil)
      index = messages.find_index { |m| m.uid == uid }
      raise "UID #{uid} not found" if !index

      messages[index].length = length if length
      messages[index].flags = flags if flags
      save
    end

    # Get a copy of message metadata
    # @param uid [Integer] a message UID
    # @return [Serializer::Message]
    def get(uid)
      message = messages.find { |m| m.uid == uid }
      message&.dup
    end

    # Deletes the metadata file
    # and discards stored attributes
    # @return [void]
    def delete
      return if !exist?

      Logger.logger.info("Deleting metadata file '#{pathname}'")
      FileUtils.rm(pathname)
      @loaded = false
      @messages = nil
      @uid_validity = nil
      @version = nil
    end

    # Renames the metadata file, if it exists,
    # otherwise, simply stores the new name
    # @param new_path [Serializer::Files::Path] the new path
    # @return [void]
    def rename(new_path)
      if exist?
        old_pathname = pathname
        @files_path = new_path
        new_pathname = pathname
        File.rename(old_pathname, new_pathname)
      else
        @files_path = new_path
      end
    end

    # @return [Integer] the UID validity for the folder
    def uid_validity
      ensure_loaded
      @uid_validity
    end

    # Sets the folder's UID validity and saves the metadata file
    # @param value [Integer] the new UID validity
    # @return [void]
    def uid_validity=(value)
      ensure_loaded
      @uid_validity = value
      save
    end

    # @return [Array<Hash>]
    def messages
      ensure_loaded
      @messages
    end

    # @return [Array<Integer>] The uids of all messages
    def uids
      messages.map(&:uid)
    end

    # Update a message's UID
    # @param old [Integer] the existing message UID
    # @param new [Integer] the new UID to apply to the message
    # @raise [RuntimeError] if the new UID already exists
    # @return [void]
    def update_uid(old, new)
      existing = messages.find_index { |m| m.uid == new }
      raise "UID #{new} already exists" if existing

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
    # @raise [RuntimeError] if UID validity has not been set
    # @return [void]
    def save
      return if tsx.in_transaction?

      ensure_loaded

      save_internal(version: CURRENT_VERSION, uid_validity: uid_validity, messages: messages)
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
        case data[:version]
        when CURRENT_VERSION
          @messages = data[:messages].map { |m| Serializer::Message.new(mbox: mbox, **m) }
          @version = CURRENT_VERSION
        when 3
          @messages = load_v3_messages(data[:messages])
          @uid_validity = data[:uid_validity]
          @version = CURRENT_VERSION
          @loaded = true
          save_internal(version: CURRENT_VERSION, uid_validity: uid_validity, messages: messages)
          return
        end
        @uid_validity = data[:uid_validity]
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
      return nil if !loadable_version?(data[:version])
      return nil if !data.key?(:uid_validity)
      return nil if !data.key?(:messages)
      return nil if !data[:messages].is_a?(Array)

      data
    end

    def loadable_version?(version)
      LOADABLE_VERSIONS.include?(version)
    end

    def load_v3_messages(message_data)
      messages = []
      offset = 0
      new_content = +""
      message_data.each do |m|
        raw = mbox.read(m[:offset], m[:length])
        original = Email::Mboxrd::Message.from_serialized_v3(raw)
        serialized = original.to_serialized
        messages << Serializer::Message.new(
          mbox: mbox, uid: m[:uid], offset: offset,
          length: serialized.bytesize, flags: m[:flags] || []
        )
        new_content << serialized
        offset += serialized.bytesize
      end
      File.open(mbox.pathname, "wb") { |f| f.write(new_content) }
      messages
    end

    def mbox
      @mbox ||= Serializer::Mbox.new(files_path: files_path)
    end

    def tsx
      @tsx ||= Serializer::Transaction.new(owner: self)
    end
  end
end
