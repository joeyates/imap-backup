module Imap; end

module Imap::Backup
  # Processes parameters to run the `migrate` command via command-line parameters
  module CLI::Migrate
    include Thor::Actions
    include CLI::Helpers

    LONG_DESCRIPTION = <<~DESC.freeze
      This command is deprecated and will be removed in a future version.
      Use 'copy' instead.

      All emails which have been backed up for the "source account" (SOURCE_EMAIL) are
      uploaded to the "destination account" (DESTINATION_EMAIL).

      Some configuration may be necessary, as follows:

      #{CLI::Helpers::NAMESPACE_CONFIGURATION_DESCRIPTION}

      Finally, if you want to delete existing emails in destination folders,
      use the `--reset` option. In this case, all existing emails are
      deleted before uploading the migrated emails.
    DESC

    def self.included(base)
      base.class_eval do
        desc(
          "migrate SOURCE_EMAIL DESTINATION_EMAIL [OPTIONS]",
          "(Deprecated) Uploads backed-up emails from account SOURCE_EMAIL " \
          "to account DESTINATION_EMAIL"
        )
        long_desc LONG_DESCRIPTION
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
          desc: "DANGER! This option deletes all messages from destination " \
                "folders before uploading",
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
          CLI::Transfer.new(:migrate, source_email, destination_email, non_logging_options).run
        end
      end
    end
  end
end
