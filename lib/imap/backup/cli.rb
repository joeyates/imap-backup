require "thor"

class Imap::Backup::CLI < Thor
  require "imap/backup/cli/helpers"

  autoload :Backup, "imap/backup/cli/backup"
  autoload :Folders, "imap/backup/cli/folders"
  autoload :Local, "imap/backup/cli/local"
  autoload :Remote, "imap/backup/cli/remote"
  autoload :Restore, "imap/backup/cli/restore"
  autoload :Setup, "imap/backup/cli/setup"
  autoload :Status, "imap/backup/cli/status"

  include Helpers

  default_task :backup

  def self.exit_on_failure?
    true
  end

  def self.accounts_option
    method_option(
      "accounts",
      type: :string,
      banner: "a comma-separated list of accounts (defaults to all configured accounts)",
      aliases: ["-a"]
    )
  end

  desc "backup [OPTIONS]", "Run the backup"
  long_desc <<~DESC
    Downloads any emails not yet present locally.
    Runs the backup for each configured account,
    or for those requested via the --accounts option.
    By default all folders, are backed up.
    The setup tool can be used to choose a specific list of folders to back up.
  DESC
  accounts_option
  def backup
    Backup.new(symbolized(options)).run
  end

  desc "folders [OPTIONS]", "This command is deprecated, use `imap-backup remote folders ACCOUNT`"
  long_desc <<~DESC
    Lists all folders of all configured accounts.
    This command is deprecated.
    Instead, use a combination of `imap-backup local accounts` to get the list of accounts,
    and `imap-backup remote folders ACCOUNT` to get the folder list.
  DESC
  accounts_option
  def folders
    Folders.new(symbolized(options)).run
  end

  desc "restore [OPTIONS]", "This command is deprecated, use `imap-backup restore ACCOUNT`"
  long_desc <<~DESC
    By default, restores all local emails to their respective servers.
    This command is deprecated.
    Instead, use `imap-backup restore ACCOUNT` to restore a single account.
  DESC
  accounts_option
  def restore
    Restore.new(symbolized(options)).run
  end

  desc "setup", "Configure imap-backup"
  long_desc <<~DESC
    A menu-driven command-line application used to configure imap-backup.
    Configure email accounts to back up.
  DESC
  def setup
    Setup.new().run
  end

  desc "status", "Show backup status"
  long_desc <<~DESC
    For each configured account and folder, lists the number of emails yet to be downloaded.
  DESC
  accounts_option
  def status
    Status.new(symbolized(options)).run
  end
end
