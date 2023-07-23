module Imap; end

module Imap::Backup
  class Serializer::Transaction
    attr_accessor :owner
    attr_accessor :data

    def initialize(owner:)
      @owner = owner
      @data = nil
    end

    def clear
      @data = nil
    end

    def fail_in_transaction!(method, message: "not supported inside trasactions")
      raise "#{owner.class}##{method} #{message}" if data
    end

    def fail_outside_transaction!(method)
      raise "#{owner.class}##{method} can only be called inside a transaction" if !data
    end
  end
end
