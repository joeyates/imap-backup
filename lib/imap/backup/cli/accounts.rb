module Imap::Backup
  class CLI; end

  class CLI::Accounts
    include Enumerable

    attr_reader :required_accounts

    def initialize(required_accounts = [])
      @required_accounts = required_accounts
    end

    def each(&block)
      return enum_for(:each) if !block

      accounts.each(&block)
    end

    private

    def accounts
      @accounts ||=
        if required_accounts.empty?
          config.accounts
        else
          config.accounts.select do |account|
            required_accounts.include?(account.username)
          end
        end
    end

    def config
      @config ||= begin
        exists = Configuration.exist?
        if !exists
          path = Configuration.default_pathname
          raise ConfigurationNotFound, "Configuration file '#{path}' not found"
        end
        Configuration.new
      end
    end
  end
end
