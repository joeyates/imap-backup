require "imap/backup/account/folder_mapper"
require "imap/backup/cli/backup"
require "imap/backup/cli/helpers"
require "imap/backup/logger"
require "imap/backup/migrator"
require "imap/backup/mirror"

module Imap; end

module Imap::Backup
  # Implements migration and mirroring
  class CLI::Transfer
    include CLI::Helpers

    # The possible values for the action parameter
    ACTIONS = %i(copy migrate mirror).freeze

    def initialize(action, source_email, destination_email, options)
      @action = action
      @source_email = source_email
      @destination_email = destination_email
      @options = options
      @automatic_namespaces = nil
      @config_path = nil
      @destination_delimiter = nil
      @destination_prefix = nil
      @reset = nil
      @source_delimiter = nil
      @source_prefix = nil
    end

    # @!method run
    #   @raise [RuntimeError] if the indicated action is unknown,
    #     or the source and destination accounts are the same,
    #     or either of the accounts is not configured,
    #     or incompatible namespace/delimiter parameters have been supplied
    #   @return [void]
    def run
      raise "Unknown action '#{action}'" if !ACTIONS.include?(action)

      process_options!
      warn_if_source_account_is_not_in_mirror_mode if action == :mirror
      run_backup if %i(copy mirror).include?(action)

      folders.each do |serializer, folder|
        case action
        when :copy
          Mirror.new(serializer, folder, reset: false).run
        when :migrate
          Migrator.new(serializer, folder, reset: reset).run
        when :mirror
          Mirror.new(serializer, folder, reset: true).run
        end
      end
    end

    private

    attr_reader :action
    attr_accessor :automatic_namespaces
    attr_accessor :config_path
    attr_accessor :destination_delimiter
    attr_reader :destination_email
    attr_accessor :destination_prefix
    attr_reader :options
    attr_accessor :reset
    attr_accessor :source_delimiter
    attr_reader :source_email
    attr_accessor :source_prefix

    def process_options!
      self.automatic_namespaces = options[:automatic_namespaces] || false
      self.config_path = options[:config]
      self.destination_delimiter = options[:destination_delimiter]
      self.destination_prefix = options[:destination_prefix]
      self.source_delimiter = options[:source_delimiter]
      self.source_prefix = options[:source_prefix]
      self.reset = options[:reset] || false
      check_accounts!
      choose_prefixes_and_delimiters!
    end

    def check_accounts!
      if destination_email == source_email
        raise "Source and destination accounts cannot be the same!"
      end

      raise "Account '#{destination_email}' does not exist" if !destination_account

      raise "Account '#{source_email}' does not exist" if !source_account

      if !source_account.available_for_migration?
        raise "Account '#{source_email}' is not available for migration (status: #{source_account.status})"
      end

      if !destination_account.available_for_migration?
        raise "Account '#{destination_email}' is not available for migration (status: #{destination_account.status})"
      end
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
      raise "--automatic-namespaces is incompatible with --destination-prefix" if destination_prefix
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

    def run_backup
      CLI::Backup.new(config: config_path, accounts: source_email).run
    end

    def warn_if_source_account_is_not_in_mirror_mode
      return if source_account.mirror_mode

      message =
        "The account '#{source_account.username}' " \
        "is not set up to make mirror backups"
      Logger.logger.warn message
    end

    def config
      @config ||= load_config(config: config_path)
    end

    def enumerator_options
      {
        account: source_account,
        destination: destination_account,
        destination_delimiter: destination_delimiter,
        destination_prefix: destination_prefix,
        source_delimiter: source_delimiter,
        source_prefix: source_prefix
      }
    end

    def folders
      Account::FolderMapper.new(**enumerator_options)
    end

    def destination_account
      config.accounts.find { |a| a.username == destination_email }
    end

    def source_account
      config.accounts.find { |a| a.username == source_email }
    end
  end
end
