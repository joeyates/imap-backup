module Imap; end

module Imap::Backup
  # Stores data during a transaction
  class Serializer::Transaction
    attr_reader :data

    def initialize(owner:)
      @data = nil
      @owner = owner
      @in_transaction = false
    end

    def begin(data, &block)
      @data = data
      @in_transaction = true
      block.call
      @in_transaction = false
    end

    def clear
      @data = nil
    end

    def in_transaction?
      @in_transaction
    end

    def fail_in_transaction!(method, message: "not supported inside trasactions")
      raise "#{owner.class}##{method} #{message}" if in_transaction?
    end

    def fail_outside_transaction!(method)
      raise "#{owner.class}##{method} can only be called inside a transaction" if !in_transaction?
    end

    private

    attr_reader :owner
  end
end
