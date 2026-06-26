require "forwardable"

require "imap/backup/email/mboxrd/message"
require "imap/backup/logger"
require "imap/backup/serializer/appender"
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
      check_integrity!
      delete
      each_message
      get
      imap
      mbox
      messages
      reload
      update
      update_uid
      uids
      uid_validity
    ]

    # @return [Serializer::Files::Path] The path of the folder
    attr_reader :files_path

    # @param files_path [Serializer::Files::Path] the path of the folder
    def initialize(files_path:)
      @files_path = files_path
      @validated = nil
    end

    def folder
      files_path.folder_name
    end

    def path
      files_path.base_path
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
      case
      when uid_validity.nil?
        force_uid_validity(value)
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
      files.uid_validity = value
    end

    # Appends a message to the serialized data
    # @param uid [Integer] the message's UID
    # @param message [Integer] the message text
    # @param flags [Array[Symbol]] the message's flags
    # @return [void]
    def append(uid, message, flags)
      files.validate!

      appender = Serializer::Appender.new(files: files)
      appender.append(uid: uid, message: message, flags: flags)
    end

    # Calls the supplied block on each message in the folder
    # and discards those for which the block returns a false result
    # @param block [block] the block to call
    # @return [void]
    def filter(&block)
      temp_files_path = Serializer::UnusedNameFinder.new(serializer: self).run
      temp_files = Serializer::Files.new(files_path: temp_files_path)
      temp_files.uid_validity = files.uid_validity
      appender = Serializer::Appender.new(files: temp_files)
      enumerator = Serializer::MessageEnumerator.new(imap: files.imap)
      enumerator.run(uids: uids) do |message|
        keep = block.call(message)
        appender.append(uid: message.uid, message: message.body, flags: message.flags) if keep
      end
      files.delete
      temp_files.rename files_path
    end

    private

    def files
      @files ||= Serializer::Files.new(files_path: files_path)
    end

    def apply_new_uid_validity(value)
      new_files_path = rename_existing_folder
      # Clear memoization so we get updated data
      files.reload
      files.uid_validity = value

      new_files_path.folder_name
    end

    def rename_existing_folder
      new_files_path = Serializer::UnusedNameFinder.new(serializer: self).run
      files.rename new_files_path
      new_files_path
    end
  end
end
