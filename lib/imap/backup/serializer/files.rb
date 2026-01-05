require "imap/backup/naming"
require "imap/backup/serializer/directory"
require "imap/backup/serializer/imap"
require "imap/backup/serializer/integrity_checker"
require "imap/backup/serializer/mbox"
require "imap/backup/serializer/files/path"

module Imap; end

module Imap::Backup
  # Provides memoized file helpers for Serializer
  class Serializer::Files
    extend Forwardable

    def_delegator :mbox, :pathname, :mbox_pathname
    def_delegator :imap, :update

    def initialize(path:, folder:)
      @path = path
      @folder = folder
      @directory_ensured = false
      @imap = nil
      @mbox = nil
      @folder_path = nil
      @sanitized = nil
    end

    def sanitized
      @sanitized ||= Naming.to_local_path(folder)
    end

    def folder_path
      @folder_path ||= Serializer::Files::Path.new(
        base_path: path, folder_name: sanitized
      ).to_s
    end

    def imap
      @imap ||= begin
        ensure_directory
        Serializer::Imap.new(folder_path)
      end
    end

    def mbox
      @mbox ||= begin
        ensure_directory
        Serializer::Mbox.new(folder_path)
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

    # Forces a reload of the serialized files
    # @return [void]
    def reload
      @imap = nil
      @mbox = nil
    end

    def rename(new_name)
      destination = Serializer::Files::Path.new(
        base_path: path, folder_name: new_name
      ).to_s
      relative = File.dirname(new_name)
      directory_path = Serializer::Files::Path.new(
        base_path: path, folder_name: relative
      )
      directory = Serializer::Directory.new(folder_path: directory_path)
      directory.ensure_exists
      mbox.rename destination
      imap.rename destination
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
      warn_mbox = !mbox_valid && mbox.exist?
      Logger.logger.info("Mailbox '#{mbox.pathname}' is invalid") if warn_mbox

      delete

      false
    end

    private

    attr_reader :folder
    attr_reader :path

    def ensure_directory
      return if @directory_ensured

      relative = File.dirname(sanitized)
      directory_path = Serializer::Files::Path.new(
        base_path: path, folder_name: relative
      )
      directory = Serializer::Directory.new(folder_path: directory_path)
      directory.ensure_exists
      @directory_ensured = true
    end
  end
end
