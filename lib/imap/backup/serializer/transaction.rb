module Imap; end

module Imap::Backup
  # Stores data during a transaction
  class Serializer::Transaction
    # @return the transaction's stored data
    attr_reader :data

    # @param owner [any] the class using the transaction -
    #   this is used when raising errors
    def initialize(owner:)
      @data = nil
      @owner = owner
      @in_transaction = false
    end

    # Runs the transaction
    # @param data [any] the data to maintain during the transaction
    # @param block [block] the block to wrap with the transaction
    # @return [void]
    def begin(data, &block)
      @data = data
      @in_transaction = true
      block.call
      @in_transaction = false
    end

    # Clears rollback data
    # @return [void]
    def clear
      @data = nil
    end

    def in_transaction?
      @in_transaction
    end

    # Throws an exception if there is a current transaction
    # @param method [Symbol] the method where the check is run
    # @return [void]
    def fail_in_transaction!(method, message: "not supported inside trasactions")
      raise "#{owner.class}##{method} #{message}" if in_transaction?
    end

    # Throws an exception if there is not a current transaction
    # @param method [Symbol] the method where the check is run
    # @return [void]
    def fail_outside_transaction!(method)
      raise "#{owner.class}##{method} can only be called inside a transaction" if !in_transaction?
    end

    private

    attr_reader :owner
  end
end
