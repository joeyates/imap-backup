# encoding: utf-8

module Imap::Backup
  module Configuration; end

  class Configuration::List
    attr_reader :required_accounts

    def initialize(required_accounts = nil)
      @required_accounts = required_accounts
    end

    def setup_logging
      return if not config_exists?
      Imap::Backup.setup_logging config
    end

    def each_connection
      accounts.each do |account|
        connection = Account::Connection.new(account)
        yield connection
        connection.disconnect
      end
    end

    private

    def config
      return @config if @config
      if not config_exists?
        raise ConfigurationNotFound.new("Configuration file '#{Configuration::Store.default_pathname}' not found")
      end
      @config = Configuration::Store.new
    end

    def config_exists?
      Configuration::Store.exist?
    end

    def accounts
      return @accounts if @accounts
      if required_accounts.nil?
        @accounts = config.accounts
      else
        @accounts = config.accounts.select{ |account| required_accounts.include?(account[:username]) }
      end
    end
  end
end
