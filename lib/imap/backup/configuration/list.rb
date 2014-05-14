# encoding: utf-8

module Imap::Backup
  module Configuration; end

  class Configuration::List
    attr_reader :accounts

    def initialize(accounts = nil)
      if not Configuration::Store.exist?
        raise ConfigurationNotFound.new("Configuration file '#{Configuration::Store.default_pathname}' not found")
      end
      @config = Configuration::Store.new

      if accounts.nil?
        @accounts = @config.data[:accounts]
      else
        @accounts = @config.data[:accounts].select{ |account| accounts.include?(account[:username]) }
      end
    end

    def each_connection
      @accounts.each do |account|
        connection = Account::Connection.new(account)
        yield connection
        connection.disconnect
      end
    end
  end
end
