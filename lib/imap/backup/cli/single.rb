require "thor"

require "imap/backup/logger"
require "imap/backup/cli/helpers"
require "imap/backup/cli/single/backup"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  class CLI::Single < Thor
    include CLI::Helpers

    desc "backup", "Backup a single email account based on command-line parameters"
    long_desc <<~DESC
      This is a "stand-alone" backup command that doesn't require
      a configuration file.

      At a minimum, you need to supply the email, the server and the
      password. (There are three ways of specifying the password)

      $ imap-backup single backup
        --email me@example.com
        --password MyS3kr1t
        --server imap.example.com

      Instead of supplying the password directly on the command line,
      there are two alternatives.
      You can set an environment variable (with any name) to your
      password, then pass the name of the environment variable.

      For example, if MY_IMAP_PASSWORD is set to your password,

      $ imap-backup single backup
        --email me@example.com
        --password-environment-variable MY_IMAP_PASSWORD
        --server imap.example.com

      Alternatively, you can supply the name of a file that contains
      the password.

      For example, in `~/imap-password`:

      `MyS3kr1t`

      $ imap-backup single backup
        --email me@example.com
        --password-file ~/imap-password
        --server imap.example.com

      If you need to use an insecure connection (this normally happens
      when running an OAuth2 proxy), you can specify server connection options
      in JSON:

      $ imap-backup single backup
        --email me@example.com
        --password MyS3kr1t
        --server imap.example.com
        --connection-options '{"ssl":{"verify_mode":0}}'
    DESC
    method_option(
      "email",
      type: :string,
      desc: "the email address",
      required: true,
      aliases: ["-e"]
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
    def backup
      non_logging_options = Imap::Backup::Logger.setup_logging(options)
      direct = Backup.new(non_logging_options)
      direct.run
    end
  end
end
