module Imap::Backup
  class CLI; end

  class CLI::Accounts
    include Enumerable

    attr_reader :config
    attr_reader :emails

    def initialize(config:, emails: [])
      @config = config
      @emails = emails
    end

    def each(&block)
      return enum_for(:each) if !block

      accounts.each(&block)
    end

    private

    def accounts
      @accounts ||=
        if emails.empty?
          config.accounts
        else
          config.accounts.select do |account|
            emails.include?(account.username)
          end
        end
    end
  end
end
