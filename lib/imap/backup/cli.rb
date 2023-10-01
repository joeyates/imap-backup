require "thor"

require "imap/backup/logger"

module Imap; end

module Imap::Backup
  class CLI < Thor
    require "imap/backup/cli/helpers"

    autoload :Backup, "imap/backup/cli/backup"
    autoload :Folders, "imap/backup/cli/folders"
    autoload :Local, "imap/backup/cli/local"
    autoload :Remote, "imap/backup/cli/remote"
    autoload :Restore, "imap/backup/cli/restore"
    autoload :Setup, "imap/backup/cli/setup"
    autoload :Stats, "imap/backup/cli/stats"
    autoload :Transfer, "imap/backup/cli/transfer"
    autoload :Utils, "imap/backup/cli/utils"

    include Helpers

    VERSION_ARGUMENTS = %w(-v --version).freeze

    NAMESPACE_CONFIGURATION_DESCRIPTION = <<~DESC.freeze
      Some IMAP servers use namespaces (i.e. prefixes like "INBOX"),
      while others, while others concatenate the names of subfolders
      with a charater ("delimiter") other than "/".

      In these cases there are two choices.

      You can use the `--automatic-namespaces` option.
      This wil query the source and detination servers for their
      namespace configuration and will adapt paths accordingly.
      This option requires that both the source and destination
      servers are available and work with the provided parameters
      and authentication.

      If automatic configuration does not work as desired, there are the
      `--source-prefix=`, `--source-delimiter=`,
      `--destination-prefix=` and `--destination-delimiter=` parameters.
      To check what values you should use, check the output of the
      `imap-backup remote namespaces EMAIL` command.
    DESC

    default_task :backup

    def self.start(*args)
      version_argument = ARGV & VERSION_ARGUMENTS
      if version_argument.any?
        new.version
        exit 0
      end

      # By default, commands like `imap-backup help foo bar`
      # are handled by listing all `foo` methods, whereas the user
      # probably wants the detailed help for the `bar` method.
      # Move initial "help" argument to after any subcommand,
      # so we get help for the requested subcommand method.
      first_argument_is_help = ARGV[0] == "help"
      second_argument_is_subcommand = subcommands.include?(ARGV[1])
      if first_argument_is_help && second_argument_is_subcommand
        help, subcommand = ARGV.shift(2)
        ARGV.unshift(subcommand, help)
      end
      super
    end

    def self.exit_on_failure?
      true
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
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Backup.new(non_logging_options).run
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

      Some configuration may be necessary, as follows:

      #{NAMESPACE_CONFIGURATION_DESCRIPTION}

      Finally, if you want to delete existing emails in destination folders,
      use the `--reset` option. In this case, all existing emails are
      deleted before uploading the migrated emails.
    DESC
    config_option
    quiet_option
    verbose_option
    method_option(
      "automatic-namespaces",
      type: :boolean,
      desc: "automatically choose delimiters and prefixes"
    )
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
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Transfer.new(:migrate, source_email, destination_email, non_logging_options).run
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

      First, it runs the download of the SOURCE_EMAIL account.
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
      "automatic-namespaces",
      type: :boolean,
      desc: "automatically choose delimiters and prefixes"
    )
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
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Transfer.new(:mirror, source_email, destination_email, non_logging_options).run
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
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Restore.new(email, non_logging_options).run
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
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      CLI::Setup.new(non_logging_options).run
    end

    desc "stats EMAIL [OPTIONS]", "Print stats for each account folder"
    long_desc <<~DESC
      For each account folder, lists three counts of emails:

      1. "server" - those yet to be downloaded,

      2. "both" - those that exist on server and are backed up,

      3. "local" - those which are only present in the backup (as they have been deleted
        on the server).
    DESC
    config_option
    format_option
    quiet_option
    verbose_option
    def stats(email)
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Stats.new(email, non_logging_options).run
    end

    desc "utils SUBCOMMAND [OPTIONS]", "Various utilities"
    subcommand "utils", Utils

    desc "version", "Print the imap-backup version"
    def version
      Kernel.puts "imap-backup #{Imap::Backup::VERSION}"
    end
  end
end
