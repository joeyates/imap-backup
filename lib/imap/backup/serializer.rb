require "forwardable"

require "imap/backup/email/mboxrd/message"
require "imap/backup/logger"
require "imap/backup/naming"
require "imap/backup/serializer/appender"
require "imap/backup/serializer/directory"
require "imap/backup/serializer/integrity_checker"
require "imap/backup/serializer/imap"
require "imap/backup/serializer/mbox"
require "imap/backup/serializer/message_enumerator"
require "imap/backup/serializer/version2_migrator"
require "imap/backup/serializer/unused_name_finder"

module Imap; end

module Imap::Backup
  # Handles serialization for a folder
  class Serializer
    # @param path [String] an account's backup path
    # @param folder [String] a folder name
    # @return [String] the full path to a serialized folder (without file extensions)
    def self.folder_path_for(path:, folder:)
      relative = File.join(path, folder)
      File.expand_path(relative)
    end

    extend Forwardable

    def_delegator :mbox, :pathname, :mbox_pathname
    def_delegator :imap, :update

    # Get message metadata
    # @param uid [Integer] a message UID
    # @return [Serializer::Message]
    def get(uid)
      validate!
      imap.get(uid)
    end

    # @return [Array<Hash>]
    def messages
      validate!
      imap.messages
    end

    # @return [Integer] the UID validity for the folder
    def uid_validity
      validate!
      imap.uid_validity
    end

    # @return [Array<Integer>] The uids of all messages
    def uids
      validate!
      imap.uids
    end

    # Update a message's metadata, replacing its UID
    # @param old [Integer] the existing message UID
    # @param new [Integer] the new UID to apply to the message
    # @return [void]
    def update_uid(old, new)
      validate!
      imap.update_uid(old, new)
    end

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

    # Checks that the metadata files are valid, migrates the metadata file
    # from older versions, if necessary,
    # or deletes any existing files if the pair are not valid.
    # @return [Boolean] indicates whether there are existing, valid files
    def validate!
      return true if @validated

      optionally_migrate2to3

      imap_valid = imap.valid?
      mbox_valid = mbox.valid?
      if imap_valid && mbox_valid
        @validated = true
        return true
      end
      warn_imap = !imap_valid && imap.exist?
      Logger.logger.info("Metadata file '#{imap.pathname}' is invalid") if warn_imap
      warn_mbox = !mbox_valid && mbox.exist?
      Logger.logger.info("Mailbox '#{mbox.pathname}' is invalid") if warn_mbox

      delete

      false
    end

    # Checks that the folder's data is stored correctly
    # @return [void]
    def check_integrity!
      IntegrityChecker.new(imap: imap, mbox: mbox).run
    end

    # Deletes the serialized data
    # @return [void]
    def delete
      imap.delete
      mbox.delete
      reload
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
      validate!

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
      validate!

      internal_force_uid_validity(value)
    end

    # Appends a message to the serialized data
    # @param uid [Integer] the message's UID
    # @param message [Integer] the message text
    # @param flags [Array[Symbol]] the message's flags
    # @return [void]
    def append(uid, message, flags)
      validate!

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

      validate!

      enumerator = Serializer::MessageEnumerator.new(imap: imap)
      enumerator.run(uids: required_uids, &block)
    end

    # Calls the supplied block on each message in the folder
    # and discards those for which the block returns a false result
    # @param block [block] the block to call
    # @return [void]
    def filter(&block)
      temp_name = Serializer::UnusedNameFinder.new(serializer: self).run
      temp_folder_path = self.class.folder_path_for(path: path, folder: temp_name)
      new_mbox = Serializer::Mbox.new(temp_folder_path)
      new_imap = Serializer::Imap.new(temp_folder_path)
      new_imap.uid_validity = imap.uid_validity
      appender = Serializer::Appender.new(folder: temp_name, imap: new_imap, mbox: new_mbox)
      enumerator = Serializer::MessageEnumerator.new(imap: imap)
      enumerator.run(uids: uids) do |message|
        keep = block.call(message)
        appender.append(uid: message.uid, message: message.body, flags: message.flags) if keep
      end
      imap.delete
      new_imap.rename imap.folder_path
      mbox.delete
      new_mbox.rename mbox.folder_path
      reload
    end

    # @return [String] the path to the serialized folder (without file extensions)
    def folder_path
      self.class.folder_path_for(path: path, folder: sanitized)
    end

    # @return [String] The folder's name adapted for using as a file name
    def sanitized
      @sanitized ||= Naming.to_local_path(folder)
    end

    # Forces a reload of the serialized files
    # @return [void]
    def reload
      @imap = nil
      @mbox = nil
    end

    private

    def rename(new_name)
      destination = self.class.folder_path_for(path: path, folder: new_name)
      relative = File.dirname(new_name)
      directory = Serializer::Directory.new(path, relative)
      directory.ensure_exists
      mbox.rename destination
      imap.rename destination
    end

    def internal_force_uid_validity(value)
      imap.uid_validity = value
      mbox.touch
    end

    def mbox
      @mbox ||=
        begin
          ensure_containing_directory
          Serializer::Mbox.new(folder_path)
        end
    end

    def imap
      @imap ||=
        begin
          ensure_containing_directory
          Serializer::Imap.new(folder_path)
        end
    end

    def optionally_migrate2to3
      migrator = Version2Migrator.new(folder_path)
      return if !migrator.required?

      Logger.logger.info <<~MESSAGE
        Local metadata for folder '#{folder_path}' is currently stored in the version 2 format.

        Migrating to the version 3 format...
      MESSAGE

      migrator.run
      # Ensure new metadata gets loaded
      @imap = nil
    end

    def ensure_containing_directory
      relative = File.dirname(sanitized)
      directory = Serializer::Directory.new(path, relative)
      directory.ensure_exists
    end

    def apply_new_uid_validity(value)
      new_name = rename_existing_folder
      # Clear memoization so we get empty data
      @mbox = nil
      @imap = nil
      internal_force_uid_validity(value)

      new_name
    end

    def rename_existing_folder
      new_name = Serializer::UnusedNameFinder.new(serializer: self).run
      rename new_name
      new_name
    end
  end
end
