require "thor"

module Imap; end

module Imap::Backup
  class CLI < Thor
    require "imap/backup/cli/helpers"

    autoload :Backup, "imap/backup/cli/backup"
    autoload :Folders, "imap/backup/cli/folders"
    autoload :Local, "imap/backup/cli/local"
    autoload :Migrate, "imap/backup/cli/migrate"
    autoload :Remote, "imap/backup/cli/remote"
    autoload :Restore, "imap/backup/cli/restore"
    autoload :Setup, "imap/backup/cli/setup"
    autoload :Status, "imap/backup/cli/status"
    autoload :Utils, "imap/backup/cli/utils"

    include Helpers

    default_task :backup

    def self.exit_on_failure?
      true
    end

    def self.accounts_option
      method_option(
        "accounts",
        type: :string,
        desc: "a comma-separated list of accounts (defaults to all configured accounts)",
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

    desc "local SUBCOMMAND [OPTIONS]", "View local info"
    subcommand "local", Local

    desc "migrate SOURCE_EMAIL DESTINATION_EMAIL [OPTIONS]",
      "[Experimental] Uploads backed-up emails from account SOURCE_EMAIL to account DESTINATION_EMAIL"
    long_desc <<~DESC
      All emails which have been backed up for the "source account" (SOURCE_EMAIL) are
      uploaded to the "destination account" (DESTINATION_EMAIL).

      When one or other account has namespaces (i.e. prefixes like "INBOX."),
      use the `--source-prefix=` and/or `--destination-prefix=` options.

      Usually, you should migrate to an account with empty folders.

      Before migrating each folder, `imap-backup` checks if the destination
      folder is empty.

      If it finds a non-empty destination folder, it halts with an error.

      If you are sure that these destination emails can be deleted,
      use the `--reset` option. In this case, all existing emails are
      deleted before uploading the migrated emails.
    DESC
    method_option(
      "destination-prefix",
      type: :string,
      desc: "the prefix (namespace) to add to destination folder names",
      aliases: ["-d"]
    )
    method_option(
      "reset",
      type: :boolean,
      desc: "DANGER! This option deletes all messages from destination folders before uploading",
      aliases: ["-r"]
    )
    method_option(
      "source-prefix",
      type: :string,
      desc: "the prefix (namespace) to strip from source folder names",
      aliases: ["-s"]
    )
    def migrate(source_email, destination_email)
      Migrate.new(source_email, destination_email, symbolized(options)).run
    end

    desc "remote SUBCOMMAND [OPTIONS]", "View info about online accounts"
    subcommand "remote", Remote

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
      Setup.new.run
    end

    desc "status", "Show backup status"
    long_desc <<~DESC
      For each configured account and folder, lists the number of emails yet to be downloaded.
    DESC
    accounts_option
    def status
      Status.new(symbolized(options)).run
    end

    desc "utils SUBCOMMAND [OPTIONS]", "Various utilities"
    subcommand "utils", Utils
  end
end
