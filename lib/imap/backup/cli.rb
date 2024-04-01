require "thor"

require "imap/backup/logger"
require "imap/backup/version"

module Imap; end

module Imap::Backup
  # Top-level cli call handler
  class CLI < Thor
    require "imap/backup/cli/helpers"

    autoload :Backup, "imap/backup/cli/backup"
    autoload :Local, "imap/backup/cli/local"
    autoload :Remote, "imap/backup/cli/remote"
    autoload :Restore, "imap/backup/cli/restore"
    autoload :Setup, "imap/backup/cli/setup"
    autoload :Single, "imap/backup/cli/single"
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
      This will query the source and detination servers for their
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
    private_constant :NAMESPACE_CONFIGURATION_DESCRIPTION

    default_task :backup

    # Overrides {https://www.rubydoc.info/gems/thor/Thor%2FBase%2FClassMethods:start Thor's method}
    # to handle '--version' and rearrange parameters if 'help' is passed
    # @return [void]
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

    # see {https://www.rubydoc.info/gems/thor/Thor/Base/ClassMethods#exit_on_failure%3F-instance_method Thor documentation}
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
    # Runs account backups
    # @return [void]
    def backup
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Backup.new(non_logging_options).run
    end

    desc(
      "copy SOURCE_EMAIL DESTINATION_EMAIL [OPTIONS]",
      "Copies emails from the SOURCE account to the DESTINATION account, avoiding duplicates"
    )
    long_desc <<~DESC
      This command copies messages from the SOURCE_EMAIL account
      to the DESTINATION_EMAIL account. It keeps track of copied
      messages and avoids duplicate copies.

      Any other messages that are present on the DESTINATION_EMAIL account
      are not affected.

      If a folder list is configured for the SOURCE_EMAIL account,
      only the folders indicated by the setting are copied.

      First, it runs the download of the SOURCE_EMAIL account.

      When the copy command is used, for each folder that is processed,
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
    # Copies messages from one email account to another
    # @return [void]
    def copy(source_email, destination_email)
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Transfer.new(:copy, source_email, destination_email, non_logging_options).run
    end

    desc "local SUBCOMMAND [OPTIONS]", "View local info"
    subcommand "local", Local

    desc(
      "migrate SOURCE_EMAIL DESTINATION_EMAIL [OPTIONS]",
      "(Deprecated) Uploads backed-up emails from account SOURCE_EMAIL to account DESTINATION_EMAIL"
    )
    long_desc <<~DESC
      This command is deprecated and will be removed in a future version.
      Use 'copy' instead.

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
    # Migrates emails from one account to another
    # @return [void]
    def migrate(source_email, destination_email)
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Transfer.new(:migrate, source_email, destination_email, non_logging_options).run
    end

    desc(
      "mirror SOURCE_EMAIL DESTINATION_EMAIL [OPTIONS]",
      "(Deprecated) Keeps the DESTINATION_EMAIL account aligned with the SOURCE_EMAIL account"
    )
    long_desc <<~DESC
      This command is deprecated and will be removed in a future version.
      Use 'copy' instead.

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
    # Keeps one email account in line with another
    # @return [void]
    def mirror(source_email, destination_email)
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Transfer.new(:mirror, source_email, destination_email, non_logging_options).run
    end

    desc "remote SUBCOMMAND [OPTIONS]", "View info about online accounts"
    subcommand "remote", Remote

    desc "restore EMAIL [OPTIONS]", "Restores a single account"
    long_desc <<~DESC
      Restores all backed-up emails for the supplied account to
      their original server.
    DESC
    accounts_option
    config_option
    quiet_option
    verbose_option
    method_option(
      "delimiter",
      type: :string,
      desc: "the delimiter for folder names"
    )
    method_option(
      "prefix",
      type: :string,
      desc: "a prefix (namespace) to add to folder names",
      aliases: ["-d"]
    )
    # Restores backed up emails to an account
    # @return [void]
    def restore(email = nil)
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Restore.new(email, non_logging_options).run
    end

    desc "setup [OPTIONS]", "Configure imap-backup"
    long_desc <<~DESC
      A menu-driven command-line application used to configure imap-backup.
      Configure email accounts to back up.
    DESC
    config_option
    quiet_option
    verbose_option
    # Runs the menu-driven setup program
    # @return [void]
    def setup
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      CLI::Setup.new(non_logging_options).run
    end

    desc "single SUBCOMMAND [OPTIONS]", "Run actions on a single account"
    subcommand "single", Single

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
    # Prints various statistics about a configured account
    # @return [void]
    def stats(email)
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      Stats.new(email, non_logging_options).run
    end

    desc "utils SUBCOMMAND [OPTIONS]", "Various utilities"
    subcommand "utils", Utils

    desc "version", "Print the imap-backup version"
    # Prints the program version
    # @return [void]
    def version
      Kernel.puts "imap-backup #{Imap::Backup::VERSION}"
    end
  end
end
