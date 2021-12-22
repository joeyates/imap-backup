require "imap/backup"

module Imap::Backup::CLI::Helpers
  def symbolized(options)
    options.each.with_object({}) { |(k, v), acc| acc[k.intern] = v }
  end

  def account(email)
    connections = Imap::Backup::Configuration::List.new
    account = connections.accounts.find { |a| a.username == email }
    raise "#{email} is not a configured account" if !account

    account
  end

  def connection(email)
    account = account(email)

    Imap::Backup::Account::Connection.new(account)
  end

  def each_connection(names)
    begin
      connections = Imap::Backup::Configuration::List.new(names)
    rescue Imap::Backup::ConfigurationNotFound
      raise "imap-backup is not configured. Run `imap-backup setup`"
    end

    connections.each_connection do |connection|
      yield connection
    end
  end
end
