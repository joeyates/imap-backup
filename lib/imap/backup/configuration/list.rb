module Imap::Backup
  module Configuration; end

  class Configuration::List
    attr_reader :required_accounts

    def initialize(required_accounts = nil)
      @required_accounts = required_accounts
    end

    def setup_logging
      return if !config_exists?
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
      if !config_exists?
        path = Configuration::Store.default_pathname
        raise ConfigurationNotFound, "Configuration file '#{path}' not found"
      end
      @config = Configuration::Store.new
    end

    def config_exists?
      Configuration::Store.exist?
    end

    def accounts
      @accounts ||=
        if required_accounts.nil?
          config.accounts
        else
          config.accounts.select do |account|
            required_accounts.include?(account[:username])
          end
        end
    end
  end
end
