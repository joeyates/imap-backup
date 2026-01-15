require "imap/backup/naming"
require "imap/backup/serializer/directory_maker"
require "imap/backup/serializer/imap"
require "imap/backup/serializer/integrity_checker"
require "imap/backup/serializer/mbox"
require "imap/backup/serializer/files/path"

module Imap; end

module Imap::Backup
  # Provides memoized file helpers for Serializer
  class Serializer::Files
    extend Forwardable

    def_delegator :imap, :update

    attr_reader :files_path

    # @param files_path [Serializer::Files::Path] the path of the folder
    def initialize(files_path:)
      @files_path = files_path
      @directory_ensured = false
      @imap = nil
      @mbox = nil
      @sanitized_files_path = nil
    end

    def imap
      @imap ||= begin
        ensure_directory
        Serializer::Imap.new(files_path: sanitized_files_path)
      end
    end

    def mbox
      @mbox ||= begin
        ensure_directory
        Serializer::Mbox.new(files_path: sanitized_files_path)
      end
    end

    # Checks that the folder's data is stored correctly
    # @return [void]
    def check_integrity!
      Serializer::IntegrityChecker.new(imap: imap, mbox: mbox).run
    end

    # Deletes the serialized data
    # @return [void]
    def delete
      imap.delete
      mbox.delete
      reload
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

    # Forces a reload of the serialized files
    # @return [void]
    def reload
      @imap = nil
      @mbox = nil
    end

    # Renames the serialized files
    # @param new_files_path [Serializer::Files::Path] the new path of the folder
    # @return [void]
    def rename(new_files_path)
      Serializer::DirectoryMaker.new(files_path: new_files_path).run
      mbox.rename new_files_path
      imap.rename new_files_path
    end

    # @return [Integer] the UID validity for the folder
    def uid_validity
      validate!
      imap.uid_validity
    end

    def uid_validity=(value)
      validate!
      imap.uid_validity = value
      mbox.touch
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

    # Checks that the metadata files are valid,
    # or deletes any existing files if the pair are not valid.
    # @return [Boolean] indicates whether there are existing, valid files
    def validate!
      return true if @validated

      imap_valid = imap.valid?
      mbox_valid = mbox.valid?
      if imap_valid && mbox_valid
        @validated = true
        return true
      end
      warn_imap = !imap_valid && imap.exist?
      Logger.logger.info("Metadata file '#{imap.pathname}' is invalid") if warn_imap

      delete

      false
    end

    private

    def ensure_directory
      return if @directory_ensured

      Serializer::DirectoryMaker.new(files_path: sanitized_files_path).run
      @directory_ensured = true
    end

    def sanitized
      @sanitized ||= Naming.to_local_path(files_path.folder_name)
    end

    def sanitized_files_path
      @sanitized_files_path ||= Serializer::Files::Path.new(
        base_path: files_path.base_path, folder_name: sanitized
      )
    end
  end
end
