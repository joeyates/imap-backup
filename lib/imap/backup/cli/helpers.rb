require "imap/backup"
require "imap/backup/cli/accounts"

module Imap::Backup::CLI::Helpers
  def symbolized(options)
    options.each.with_object({}) { |(k, v), acc| acc[k.intern] = v }
  end

  def account(email)
    accounts = Imap::Backup::CLI::Accounts.new
    account = accounts.find { |a| a.username == email }
    raise "#{email} is not a configured account" if !account

    account
  end

  def connection(email)
    account = account(email)

    Imap::Backup::Account::Connection.new(account)
  end

  def each_connection(names)
    begin
      accounts = Imap::Backup::CLI::Accounts.new(names)
    rescue Imap::Backup::ConfigurationNotFound
      raise "imap-backup is not configured. Run `imap-backup setup`"
    end

    accounts.each_connection do |connection|
      yield connection
    end
  end
end
