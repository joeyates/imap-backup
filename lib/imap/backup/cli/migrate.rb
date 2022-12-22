require "imap/backup/cli/folder_enumerator"
require "imap/backup/migrator"

module Imap::Backup
  class CLI::Migrate < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :destination_delimiter
    attr_reader :destination_email
    attr_reader :destination_prefix
    attr_reader :config_path
    attr_reader :reset
    attr_reader :source_delimiter
    attr_reader :source_email
    attr_reader :source_prefix

    def initialize(
      source_email,
      destination_email,
      config: nil,
      destination_delimiter: "/",
      destination_prefix: "",
      reset: false,
      source_delimiter: "/",
      source_prefix: ""
    )
      super([])
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
