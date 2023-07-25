module Imap; end

module Imap::Backup
  class Serializer::Transaction
    attr_reader :owner

    def initialize(owner:)
      @data = nil
      @owner = owner
      @running = false
    end

    def start
      @running = true
    end

    def clear
      @data = nil
      @running = false
    end

    def data
      raise "#{self.class} not started" if !in_transaction?

      @data
    end

    def data=(value)
      raise "#{self.class} not started" if !in_transaction?

      @data = value
    end

    def in_transaction?
      @running
    end

    def fail_in_transaction!(method, message: "not supported inside trasactions")
      raise "#{owner.class}##{method} #{message}" if in_transaction?
    end

    def fail_outside_transaction!(method)
      raise "#{owner.class}##{method} can only be called inside a transaction" if !in_transaction?
    end
  end
end
