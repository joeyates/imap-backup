require "forwardable"

require "imap/backup/email/mboxrd/message"
require "imap/backup/serializer/imap"
require "imap/backup/serializer/mbox"
require "imap/backup/serializer/transaction"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Wraps the Serializer, delaying metadata changes
  class Serializer::DelayedMetadataSerializer
    extend Forwardable

    def_delegator :serializer, :uids

    # @param serializer [Serializer] the serializer for a folder
    def initialize(serializer:)
      @serializer = serializer
      @tsx = nil
    end

    # Initializes the metadata and mailbox transactions, then calls the supplied block.
    # Once the block has finished, commits changes to metadata
    # @param block [block] the block that is wrapped by the transaction
    #
    # @raise any error ocurring during the commit phase
    # @return [void]
    def transaction(&block)
      tsx.fail_in_transaction!(:transaction, message: "nested transactions are not supported")

      tsx.begin({appends: [], updates: []}) do
        mbox.transaction do
          block.call

          commit

          serializer.reload
        end
      end
    end

    # Sets the folder's UID validity via the serializer
    #
    # @param uid_validity [Integer] the UID validity to apply
    # @raise [RuntimeError] if called inside a transaction
    # @return [void]
    def apply_uid_validity(uid_validity)
      tsx.fail_in_transaction!(
        :transaction,
        message: "UID validity cannot be changed in a transaction"
      )

      serializer.apply_uid_validity(uid_validity)
    end

    # Appends a message to the mbox file and adds the appended message's metadata
    # to the transaction
    #
    # @param uid [Integer] the UID of the message
    # @param message [String] the message
    # @param flags [Array<Symbol>] the flags for the message
    # @return [void]
    def append(uid, message, flags)
      tsx.fail_outside_transaction!(:append)
      mboxrd_message = Email::Mboxrd::Message.new(message)
      serialized = mboxrd_message.to_serialized
      tsx.data[:appends] << {uid: uid, length: serialized.bytesize, flags: flags}
      mbox.append(serialized)
    end

    # Stores changes to a message's metadata for later update
    #
    # @param uid [Integer] the UID of the message
    # @param length [Integer] the length of the message
    # @param flags [Array<Symbol>] the flags for the message
    # @return [void]
    def update(uid, length: nil, flags: nil)
      tsx.fail_outside_transaction!(:update)
      tsx.data[:updates] << {uid: uid, length: length, flags: flags}
    end

    private

    attr_reader :serializer

    def commit
      # rubocop:disable Lint/RescueException
      imap.transaction do
        tsx.data[:appends].each do |m|
          imap.append m[:uid], m[:length], flags: m[:flags]
        end
        tsx.data[:updates].each do |m|
          imap.update m[:uid], length: m[:length], flags: m[:flags]
        end
      rescue Exception => e
        Logger.logger.error "#{self.class} handling #{e.class}"
        imap.rollback
        raise e
      end
      # rubocop:enable Lint/RescueException
    end

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
