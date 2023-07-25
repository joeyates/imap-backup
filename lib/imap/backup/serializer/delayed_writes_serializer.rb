require "imap/backup/serializer/appender"
require "imap/backup/serializer/imap"
require "imap/backup/serializer/mbox"
require "imap/backup/serializer/transaction"

module Imap; end

module Imap::Backup
  class Serializer::DelayedWritesSerializer
    extend Forwardable

    attr_reader :serializer

    def_delegators :serializer, :sanitized, :uids

    def initialize(serializer:)
      @serializer = serializer
      @tsx = nil
    end

    def transaction(&block)
      tsx.fail_in_transaction!(:transaction, message: "nested transactions are not supported")

      tsx.start
      tsx.data = {messages: [], mbox: {length: mbox.length}}

      block.call

      commit

      tsx.clear
    end

    def commit
      tsx.fail_outside_transaction!(:commit)

      appender = Serializer::Appender.new(folder: sanitized, imap: imap, mbox: mbox)
      appender.multi(tsx.data[:messages])
      tsx.data[:messages] = []
      tsx.data[:mbox][:length] = mbox.length
    end

    def rollback
      tsx.fail_outside_transaction!(:rollback)

      mbox.rewind(tsx.data[:mbox][:length])

      tsx.clear
    end

    def append(uid, message, flags)
      tsx.fail_outside_transaction!(:append)

      tsx.data[:messages] << {uid: uid, message: message, flags: flags}
    end

    private

    def mbox
      @mbox ||= Serializer::Mbox.new(serializer.folder_path)
    end

    def imap
      @imap ||= Serializer::Imap.new(serializer.folder_path)
    end

    def tsx
      @tsx ||= Serializer::Transaction.new(owner: self)
    end
  end
end
