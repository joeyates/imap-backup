module Imap; end

module Imap::Backup
  # Processes parameters to run the `mirror` command via command-line parameters
  module CLI::Mirror
    include Thor::Actions
    include CLI::Helpers

    LONG_DESCRIPTION = <<~DESC.freeze
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

      #{CLI::Helpers::NAMESPACE_CONFIGURATION_DESCRIPTION}
    DESC

    def self.included(base)
      base.class_eval do
        desc(
          "mirror SOURCE_EMAIL DESTINATION_EMAIL [OPTIONS]",
          "(Deprecated) Keeps the DESTINATION_EMAIL account aligned with the SOURCE_EMAIL account"
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
          CLI::Transfer.new(:mirror, source_email, destination_email, non_logging_options).run
        end
      end
    end
  end
end
