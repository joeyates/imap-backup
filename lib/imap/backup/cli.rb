require "thor"

require "imap/backup/logger"
require "imap/backup/version"

module Imap; end

module Imap::Backup
  class CLI < Thor
    require "imap/backup/cli/helpers"

    autoload :Backup, "imap/backup/cli/backup"
    autoload :Direct, "imap/backup/cli/direct"
    autoload :Local, "imap/backup/cli/local"
    autoload :Remote, "imap/backup/cli/remote"
    autoload :Restore, "imap/backup/cli/restore"
    autoload :Setup, "imap/backup/cli/setup"
    autoload :Stats, "imap/backup/cli/stats"
    autoload :Transfer, "imap/backup/cli/transfer"
    autoload :Utils, "imap/backup/cli/utils"

    include Helpers

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

    def self.start(args)
      if args.include?("--version")
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
    refresh_option
    verbose_option
    def backup
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Backup.new(non_logging_options).run
    end

    desc "direct", "Backup a single email account based on command-line parameters"
    method_option(
      "username",
      type: :string,
      desc: "your email address",
      required: true,
      aliases: ["-u"]
    )
    method_option(
      "server",
      type: :string,
      desc: "the address of the IMAP server",
      required: true,
      aliases: ["-s"]
    )
    method_option(
      "password",
      type: :string,
      desc: "your password. " \
            "As an alternative, use the --password-environment-variable " \
            "or --password-file parameter. " \
            "You need to pass exactly one of these parameters. " \
            "If you pass more than one of the --password... parameters together " \
            "you will get an error.",
      aliases: ["-p"]
    )
    method_option(
      "password-environment-variable",
      type: :string,
      desc: "an environment variable that is set to your password",
      aliases: ["-e"]
    )
    method_option(
      "password-file",
      type: :string,
      desc: "a file containing your password. " \
            "Note that to make it easier to create such files, " \
            "trailing newlines will be removed. " \
            "If you happen to have a password that ends in a newline (!), " \
            "you can't use this parameter.",
      aliases: ["-W"]
    )
    method_option(
      "path",
      type: "string",
      desc: "the path of the directory where backups are to be saved. " \
            "If the directory does not exists, it will be created. " \
            "If not set, this is set to a diretory under the current path " \
            "which is derived from the username, by replacing '@' with '_'.",
      aliases: ["-P"]
    )
    method_option(
      "folder",
      type: :string,
      desc: "a folder (this option can be given any number of times). " \
            "By default, all of an account's folders are backed up. " \
            "If you supply any --folder parameters, " \
            "only **those** folders are backed up. " \
            "See also --folder-blacklist.",
      repeatable: true,
      aliases: ["-F"]
    )
    method_option(
      "folder-blacklist",
      type: :boolean,
      desc: "if this option is given, the list of --folders specified " \
            "will treated as a blacklist - " \
            "those folders will be skipped and " \
            "all others will be backed up.",
      default: false,
      aliases: ["-b"]
    )
    method_option(
      "mirror",
      type: :boolean,
      desc: "if this option is given, " \
            "emails that are removed from the server " \
            "will be removed from the local backup.",
      aliases: ["-m"]
    )
    method_option(
      "multi-fetch-size",
      type: :numeric,
      desc: "the number of emails to download at a time",
      default: 1,
      aliases: ["-n"]
    )
    method_option(
      "connection-options",
      type: :string,
      desc: "an optional JSON string with options for the IMAP connection",
      aliases: ["-o"]
    )
    method_option(
      "download-strategy",
      type: :string,
      desc: "the download strategy to adopt. " \
            "For details, see the documentation for this setting " \
            "in the setup program.",
      enum: %w(delay direct),
      default: "delay",
      aliases: ["-S"]
    )
    refresh_option
    method_option(
      "reset-seen-flags-after-fetch",
      type: :boolean,
      desc: "reset 'Seen' flags after backup. " \
            "For details, see the documentation for this setting " \
            "in the setup program.",
      aliases: ["-R"]
    )
    quiet_option
    verbose_option
    def direct
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Direct.new(non_logging_options).run
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

      Some configuration may be necessary, as follows:

      #{NAMESPACE_CONFIGURATION_DESCRIPTION}
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
