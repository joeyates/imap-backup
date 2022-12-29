require "thor"
require "imap/backup/logger"

module Imap; end

module Imap::Backup
  class CLI < Thor
    require "imap/backup/cli/helpers"

    autoload :Backup, "imap/backup/cli/backup"
    autoload :Folders, "imap/backup/cli/folders"
    autoload :Local, "imap/backup/cli/local"
    autoload :Migrate, "imap/backup/cli/migrate"
    autoload :Mirror, "imap/backup/cli/mirror"
    autoload :Remote, "imap/backup/cli/remote"
    autoload :Restore, "imap/backup/cli/restore"
    autoload :Setup, "imap/backup/cli/setup"
    autoload :Stats, "imap/backup/cli/stats"
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
    config_option
    quiet_option
    verbose_option
    method_option(
      "refresh",
      type: :boolean,
      desc: "in 'keep all emails' mode, update flags for messages that are already downloaded",
      aliases: ["-r"]
    )
    def backup
      Imap::Backup::Logger.setup_logging options
      Backup.new(options).run
    end

    desc "local SUBCOMMAND [OPTIONS]", "View local info"
    subcommand "local", Local

    desc(
      "migrate SOURCE_EMAIL DESTINATION_EMAIL [OPTIONS]",
      "Uploads backed-up emails from account SOURCE_EMAIL to account DESTINATION_EMAIL"
    )
    long_desc <<~DESC
      All emails which have been backed up for the "source account" (SOURCE_EMAIL) are
      uploaded to the "destination account" (DESTINATION_EMAIL).

      When one or other account has namespaces (i.e. prefixes like "INBOX"),
      use the `--source-prefix=` and/or `--destination-prefix=` options.

      When one or other account uses a delimiter other than `/` (i.e. `.`),
      use the `--source-delimiter=` and/or `--destination-delimiter=` options.

      Usually, you should migrate to an account with empty folders.

      Before migrating each folder, `imap-backup` checks if the destination
      folder is empty.

      If it finds a non-empty destination folder, it halts with an error.

      If you are sure that these destination emails can be deleted,
      use the `--reset` option. In this case, all existing emails are
      deleted before uploading the migrated emails.
    DESC
    config_option
    quiet_option
    verbose_option
    method_option(
      "destination-delimiter",
      type: :string,
      desc: "the delimiter for destination folder names"
    )
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
      "source-delimiter",
      type: :string,
      desc: "the delimiter for source folder names"
    )
    method_option(
      "source-prefix",
      type: :string,
      desc: "the prefix (namespace) to strip from source folder names",
      aliases: ["-s"]
    )
    def migrate(source_email, destination_email)
      Imap::Backup::Logger.setup_logging options
      Migrate.new(source_email, destination_email, **options).run
    end

    desc(
      "mirror SOURCE_EMAIL DESTINATION_EMAIL [OPTIONS]",
      "Keeps the DESTINATION_EMAIL account aligned with the SOURCE_EMAIL account"
    )
    long_desc <<~DESC
      This command updates the DESTINATION_EMAIL account's folders to have the same contents
      as those on the SOURCE_EMAIL account.

      If a folder list is configured for the SOURCE_EMAIL account,
      only the folders indicated by the setting are copied.

      First, runs the download of the SOURCE_EMAIL account.
      If the SOURCE_EMAIL account is **not** configured to be in 'mirror' mode,
      a warning is printed.

      When the mirror command is used, for each folder that is processed,
      a new file is created alongside the normal backup files (.imap and .mbox)
      This file has a '.mirror' extension. This file contains a mapping of
      the known UIDs on the source account to those on the destination account.
    DESC
    config_option
    quiet_option
    verbose_option
    method_option(
      "destination-delimiter",
      type: :string,
      desc: "the delimiter for destination folder names"
    )
    method_option(
      "destination-prefix",
      type: :string,
      desc: "the prefix (namespace) to add to destination folder names",
      aliases: ["-d"]
    )
    method_option(
      "source-delimiter",
      type: :string,
      desc: "the delimiter for source folder names"
    )
    method_option(
      "source-prefix",
      type: :string,
      desc: "the prefix (namespace) to strip from source folder names",
      aliases: ["-s"]
    )
    def mirror(source_email, destination_email)
      Imap::Backup::Logger.setup_logging options
      Mirror.new(source_email, destination_email, **options).run
    end

    desc "remote SUBCOMMAND [OPTIONS]", "View info about online accounts"
    subcommand "remote", Remote

    desc "restore EMAIL", "Restores a single account"
    long_desc <<~DESC
      Restores all backed-up emails for the supplied account to
      their original server.
    DESC
    accounts_option
    config_option
    quiet_option
    verbose_option
    def restore(email = nil)
      Imap::Backup::Logger.setup_logging options
      Restore.new(email, options).run
    end

    desc "setup", "Configure imap-backup"
    long_desc <<~DESC
      A menu-driven command-line application used to configure imap-backup.
      Configure email accounts to back up.
    DESC
    config_option
    quiet_option
    verbose_option
    def setup
      Imap::Backup::Logger.setup_logging options
      Setup.new(options).run
    end

    desc "stats EMAIL [OPTIONS]", "Print stats for each account folder"
    long_desc <<~DESC
      For each account folder, lists emails that are yet to be downloaded "server",
      are downloaded (exist on server and locally) "both" and those which
      are only present in the backup (as they have been deleted on the server) "local".
    DESC
    config_option
    format_option
    quiet_option
    verbose_option
    def stats(email)
      Imap::Backup::Logger.setup_logging options
      Stats.new(email, options).run
    end

    desc "utils SUBCOMMAND [OPTIONS]", "Various utilities"
    subcommand "utils", Utils
  end
end
