require "imap/backup/cli/folder_enumerator"
require "imap/backup/mirror"

module Imap::Backup
  class CLI::Mirror < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :destination_delimiter
    attr_reader :destination_email
    attr_reader :destination_prefix
    attr_reader :config_path
    attr_reader :source_delimiter
    attr_reader :source_email
    attr_reader :source_prefix

    def initialize(
      source_email,
      destination_email,
      config: nil,
      destination_delimiter: "/",
      destination_prefix: "",
      source_delimiter: "/",
      source_prefix: ""
    )
      super([])
      @destination_delimiter = destination_delimiter
      @destination_email = destination_email
      @destination_prefix = destination_prefix
      @config_path = config
      @source_delimiter = source_delimiter
      @source_email = source_email
      @source_prefix = source_prefix
    end

    no_commands do
      def run
        check_accounts!
        warn_if_source_account_is_not_in_mirror_mode

        CLI::Backup.new(config: config_path, accounts: source_email).run

        folders.each do |serializer, folder|
          Mirror.new(serializer, folder).run
        end
      end

      def check_accounts!
        if destination_email == source_email
          raise "Source and destination accounts cannot be the same!"
        end

        raise "Account '#{destination_email}' does not exist" if !destination_account

        raise "Account '#{source_email}' does not exist" if !source_account
      end

      def warn_if_source_account_is_not_in_mirror_mode
        return if source_account.mirror_mode

        message =
          "The account '#{source_account.username}' " \
          "is not set up to make mirror backups"
        Logger.logger.info message
      end

      def config
        @config = load_config(config: config_path)
      end

      def enumerator_options
        {
          destination: destination_account,
          destination_delimiter: destination_delimiter,
          destination_prefix: destination_prefix,
          source: source_account,
          source_delimiter: source_delimiter,
          source_prefix: source_prefix
        }
      end

      def folders
        CLI::FolderEnumerator.new(**enumerator_options)
      end

      def destination_account
        config.accounts.find { |a| a.username == destination_email }
      end

      def source_account
        config.accounts.find { |a| a.username == source_email }
      end
    end
  end
end
