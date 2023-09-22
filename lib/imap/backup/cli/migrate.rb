require "imap/backup/cli/folder_enumerator"
require "imap/backup/migrator"

module Imap; end

module Imap::Backup
  class CLI::Migrate < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :automatic_namespaces
    attr_accessor :destination_delimiter
    attr_reader :destination_email
    attr_accessor :destination_prefix
    attr_reader :config_path
    attr_reader :reset
    attr_accessor :source_delimiter
    attr_reader :source_email
    attr_accessor :source_prefix

    def initialize(
      source_email,
      destination_email,
      automatic_namespaces: false,
      config: nil,
      destination_delimiter: nil,
      destination_prefix: nil,
      reset: false,
      source_delimiter: nil,
      source_prefix: nil
    )
      super([])
      @automatic_namespaces = automatic_namespaces
      @destination_delimiter = destination_delimiter
      @destination_email = destination_email
      @destination_prefix = destination_prefix
      @config_path = config
      @reset = reset
      @source_delimiter = source_delimiter
      @source_email = source_email
      @source_prefix = source_prefix
    end

    no_commands do
      def run
        check_accounts!
        choose_prefixes_and_delimiters!
        folders.each do |serializer, folder|
          Migrator.new(serializer, folder, reset: reset).run
        end
      end

      def check_accounts!
        if destination_email == source_email
          raise "Source and destination accounts cannot be the same!"
        end

        raise "Account '#{destination_email}' does not exist" if !destination_account

        raise "Account '#{source_email}' does not exist" if !source_account
      end

      def choose_prefixes_and_delimiters!
        if automatic_namespaces
          ensure_no_prefix_or_delimiter_parameters!
          query_servers_for_settings
        else
          add_prefix_and_delimiter_defaults
        end
      end

      def ensure_no_prefix_or_delimiter_parameters!
        if destination_delimiter
          raise "--automatic-namespaces is incompatible with --destination-delimiter"
        end
        if destination_prefix
          raise "--automatic-namespaces is incompatible with --destination-prefix"
        end
        raise "--automatic-namespaces is incompatible with --source-delimiter" if source_delimiter
        raise "--automatic-namespaces is incompatible with --source-prefix" if source_prefix
      end

      def query_servers_for_settings
        self.destination_prefix, self.destination_delimiter = account_settings(destination_account)
        self.source_prefix, self.source_delimiter = account_settings(source_account)
      end

      def account_settings(account)
        namespaces = account.client.namespace
        personal = namespaces.personal.first
        [personal.prefix, personal.delim]
      end

      def add_prefix_and_delimiter_defaults
        self.destination_delimiter ||= "/"
        self.destination_prefix ||= ""
        self.source_delimiter ||= "/"
        self.source_prefix ||= ""
      end

      def config
        @config ||= load_config(config: config_path)
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
