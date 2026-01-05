require "forwardable"

require "imap/backup/email/mboxrd/message"
require "imap/backup/logger"
require "imap/backup/serializer/appender"
require "imap/backup/serializer/directory"
require "imap/backup/serializer/files"
require "imap/backup/serializer/imap"
require "imap/backup/serializer/mbox"
require "imap/backup/serializer/message_enumerator"
require "imap/backup/serializer/files/path"
require "imap/backup/serializer/unused_name_finder"

module Imap; end

module Imap::Backup
  # Handles serialization for a folder
  class Serializer
    extend Forwardable

    def_delegators :files, *%i[
      imap
      mbox
      check_integrity!
      delete
      folder_path
      get
      messages
      reload
      sanitized
      update
      update_uid
      uid_validity
      uids
      validate!
    ]

    # @return [String] a folder name
    attr_reader :folder
    # @return [String] an account's backup path
    attr_reader :path

    # @param path [String] an account's backup path
    # @param folder [String] a folder name
    def initialize(path, folder)
      @path = path
      @folder = folder
      @validated = nil
    end

    # Calls the supplied block without implementing transactional behaviour.
    # This method is present so that this class implements the same
    # interface as {DelayedMetadataSerializer}
    # @param block [block] the block that is wrapped by the transaction
    #
    # @return [void]
    def transaction(&block)
      block.call
    end

    # Sets the folder's UID validity.
    # If the existing value is nil, it sets the new value
    # and ensures that both the metadata file and the mailbox
    # are saved.
    # If the supplied value is the same as the existing value,
    # it does nothing.
    # If the supplied valued is *different* to the existing value,
    # it renames the existing folder to a new name, and creates a
    # new folder with the supplied value.
    #
    # @param value [Integer] The new UID validity value
    #
    # @return [String, nil] The name of the new folder
    def apply_uid_validity(value)
      files.validate!

      case
      when uid_validity.nil?
        internal_force_uid_validity(value)
        nil
      when uid_validity == value
        # NOOP
        nil
      else
        apply_new_uid_validity(value)
      end
    end

    # Overwrites the UID validity of the folder
    # and ensures that both the metadata file and the mailbox
    # are saved.
    # @param value [Integer] the new UID validity
    # @return [void]
    def force_uid_validity(value)
      files.validate!

      internal_force_uid_validity(value)
    end

    # Appends a message to the serialized data
    # @param uid [Integer] the message's UID
    # @param message [Integer] the message text
    # @param flags [Array[Symbol]] the message's flags
    # @return [void]
    def append(uid, message, flags)
      files.validate!

      appender = Serializer::Appender.new(folder: sanitized, imap: imap, mbox: mbox)
      appender.append(uid: uid, message: message, flags: flags)
    end

    # Enumerates over a series of messages.
    # When called without a block, returns an Enumerator
    # @param required_uids [Array<Integer>] the UIDs of the message to enumerate over
    # @return [Enumerator, void]
    def each_message(required_uids = nil, &block)
      return enum_for(:each_message, required_uids) if !block

      required_uids ||= uids

      files.validate!

      enumerator = Serializer::MessageEnumerator.new(imap: imap)
      enumerator.run(uids: required_uids, &block)
    end

    # Calls the supplied block on each message in the folder
    # and discards those for which the block returns a false result
    # @param block [block] the block to call
    # @return [void]
    def filter(&block)
      temp_name = Serializer::UnusedNameFinder.new(serializer: self).run
      temp_path = Serializer::Files::Path.new(base_path: path, folder_name: temp_name)
      temp_folder_path = temp_path.to_s
      new_mbox = Serializer::Mbox.new(temp_folder_path)
      new_imap = Serializer::Imap.new(temp_folder_path)
      new_imap.uid_validity = imap.uid_validity
      appender = Serializer::Appender.new(folder: temp_name, imap: new_imap, mbox: new_mbox)
      enumerator = Serializer::MessageEnumerator.new(imap: imap)
      enumerator.run(uids: uids) do |message|
        keep = block.call(message)
        appender.append(uid: message.uid, message: message.body, flags: message.flags) if keep
      end
      imap_folder_path = imap.folder_path
      mbox_folder_path = mbox.folder_path
      files.delete
      new_imap.rename imap_folder_path
      new_mbox.rename mbox_folder_path
    end

    private

    def files
      @files ||= Serializer::Files.new(path: path, folder: folder)
    end

    def internal_force_uid_validity(value)
      imap.uid_validity = value
      mbox.touch
    end

    def apply_new_uid_validity(value)
      new_name = rename_existing_folder
      # Clear memoization so we get empty data
      files.reload
      internal_force_uid_validity(value)

      new_name
    end

    def rename_existing_folder
      new_name = Serializer::UnusedNameFinder.new(serializer: self).run
      files.rename new_name
      new_name
    end
  end
end
