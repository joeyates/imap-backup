require "imap/backup/serializer/transaction"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Stores messages
  class Serializer::Mbox
    # @return [String] The path of the mailbox file, without the '.mbox' extension
    attr_reader :folder_path

    # @param folder_path [String] The path of the mailbox file, without the '.mbox' extension
    def initialize(folder_path)
      @folder_path = folder_path
      @tsx = nil
    end

    # Starts a transaction
    # @param block [block] the block that is wrapped by the transaction
    # @raise re-raises errors which occur in the block
    # @return [void]
    def transaction(&block)
      tsx.fail_in_transaction!(:transaction, message: "nested transactions are not supported")

      tsx.begin({savepoint: {length: length}}) do
        block.call
      rescue StandardError => e
        rollback
        raise e
      rescue SignalException => e
        Logger.logger.error "#{self.class} handling #{e.class}"
        rollback
        raise e
      end
    end

    # Returns to the pre-transaction state
    # @return [void]
    def rollback
      tsx.fail_outside_transaction!(:rollback)

      rewind(tsx.data[:savepoint][:length])
    end

    def valid?
      exist?
    end

    # Serializes a message
    # @param message [String] the message text
    # @return [void]
    def append(message)
      File.open(pathname, "ab") do |file|
        file.write message
      end
    end

    # Reads a message from disk
    # @param offset [Integer] the start of the message inside the mailbox file
    # @param length [Integer] the length of the message (as stored on disk)
    # @return [String] the message
    def read(offset, length)
      File.open(pathname, "rb") do |f|
        f.seek offset
        f.read length
      end
    end

    # Deletes the mailbox
    # @return [void]
    def delete
      return if !exist?

      Logger.logger.info("Deleting mailbox '#{pathname}'")
      FileUtils.rm(pathname)
    end

    def exist?
      File.exist?(pathname)
    end

    # @return [Integer] The lsize of the disk file
    def length
      return nil if !exist?

      File.stat(pathname).size
    end

    # @return [String] The full path name of the mailbox
    def pathname
      "#{folder_path}.mbox"
    end

    # Renames the mailbox, if it exists,
    # otherwise, simply stores the new name
    # @param new_path [String] the new path (without extension)
    # @return [void]
    def rename(new_path)
      if exist?
        old_pathname = pathname
        @folder_path = new_path
        File.rename(old_pathname, pathname)
      else
        @folder_path = new_path
      end
    end

    # Sets the mailbox file's updated time to the current time
    # @return [void]
    def touch
      File.open(pathname, "a") {}
    end

    private

    attr_reader :savepoint

    def rewind(length)
      File.open(pathname, File::RDWR | File::CREAT, 0o644) do |f|
        f.truncate(length)
      end
    end

    def tsx
      @tsx ||= Serializer::Transaction.new(owner: self)
    end
  end
end
