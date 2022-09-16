require "imap/backup"
require "imap/backup/cli/accounts"

module Imap::Backup
  module CLI::Helpers
    def self.included(base)
      base.class_eval do
        def self.verbose_option
          method_option(
            "verbose",
            type: :boolean,
            desc: "increase the amount of logging",
            aliases: ["-v"]
          )
        end

        def self.quiet_option
          method_option(
            "quiet",
            type: :boolean,
            desc: "silence all output",
            aliases: ["-q"]
          )
        end
      end
    end

    def symbolized(options)
      options.each.with_object({}) do |(k, v), acc|
        key = k.gsub("-", "_").intern
        acc[key] = v
      end
    end

    def account(email)
      accounts = CLI::Accounts.new
      account = accounts.find { |a| a.username == email }
      raise "#{email} is not a configured account" if !account

      account
    end

    def connection(email)
      account = account(email)

      Account::Connection.new(account)
    end

    def each_connection(names)
      accounts = CLI::Accounts.new(names)

      accounts.each do |account|
        yield account.connection
      end
    rescue ConfigurationNotFound
      raise "imap-backup is not configured. Run `imap-backup setup`"
    end
  end
end
