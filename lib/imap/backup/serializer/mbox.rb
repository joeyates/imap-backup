require "imap/backup/serializer/transaction"

module Imap; end

module Imap::Backup
  # Stores messages
  class Serializer::Mbox
    attr_reader :folder_path

    def initialize(folder_path)
      @folder_path = folder_path
      @tsx = nil
    end

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

    def rollback
      tsx.fail_outside_transaction!(:rollback)

      rewind(tsx.data[:savepoint][:length])
    end

    def valid?
      exist?
    end

    def append(message)
      File.open(pathname, "ab") do |file|
        file.write message
      end
    end

    def read(offset, length)
      File.open(pathname, "rb") do |f|
        f.seek offset
        f.read length
      end
    end

    def delete
      return if !exist?

      FileUtils.rm(pathname)
    end

    def exist?
      File.exist?(pathname)
    end

    def length
      return nil if !exist?

      File.stat(pathname).size
    end

    def pathname
      "#{folder_path}.mbox"
    end

    def rename(new_path)
      if exist?
        old_pathname = pathname
        @folder_path = new_path
        File.rename(old_pathname, pathname)
      else
        @folder_path = new_path
      end
    end

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
