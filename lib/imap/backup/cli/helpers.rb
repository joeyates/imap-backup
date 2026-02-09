require "erb"
require "json"
require "tempfile"
require "thor"

require "imap/backup/cli/options"
require "imap/backup/configuration"
require "imap/backup/configuration_not_found"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  # Provides helper methods for CLI classes
  module CLI::Helpers
    def self.included(base)
      options = CLI::Options.new(base: base)
      options.define_options
    end

    # @return [String] a description of the namespace configuration
    NAMESPACE_CONFIGURATION_DESCRIPTION = <<~DESC.freeze
      Some IMAP servers use namespaces (i.e. prefixes like "INBOX"),
      while others concatenate the names of subfolders
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

    # Processes command-line parameters
    # @return [Hash] the supplied command-line parameters with
    #   with hyphens in keys replaced by underscores
    #   and the keys converted to Symbols
    def options
      @symbolized_options ||= # rubocop:disable Naming/MemoizedInstanceVariableName
        begin
          options = super
          options.each.with_object({}) do |(k, v), acc|
            key =
              if k.is_a?(String)
                k.gsub("-", "_").intern
              else
                k
              end
            acc[key] = v
          end
        end
    end

    # Loads the application configuration
    # @raise [ConfigurationNotFound] if the configuration file does not exist
    # @raise [RuntimeError] if both config and erb_configuration are provided
    # @raise [RuntimeError] if ERB template has syntax errors
    # @raise [RuntimeError] if ERB template renders invalid JSON
    # @return [Configuration]
    def load_config(**options)
      config_path = options[:config]
      erb_config_path = options[:erb_configuration]

      # Check mutual exclusivity
      raise I18n.t("cli.helpers.config_mutual_exclusivity") if config_path && erb_config_path

      # Handle ERB configuration
      return load_erb_config(erb_config_path, options) if erb_config_path

      # Handle regular JSON configuration
      path = config_path
      require_exists = options.key?(:require_exists) ? options[:require_exists] : true
      if require_exists
        exists = Configuration.exist?(path: path)
        if !exists
          expected = path || Configuration.default_pathname
          raise ConfigurationNotFound, I18n.t("cli.helpers.config_not_found", path: expected)
        end
      end
      Configuration.new(path: path)
    end

    # @raise [RuntimeError] if the account does not exist
    # @return [Account] the Account information for the email address
    def account(config, email)
      account = config.accounts.find { |a| a.username == email }
      raise I18n.t("cli.helpers.account_not_configured", email: email) if !account

      account
    end

    # @return [Array<Account>] If email addresses have been specified
    #   returns the Account configurations for them.
    #   If non have been specified, returns all account configurations
    def requested_accounts(config)
      emails = (options[:accounts] || "").split(",")
      if emails.any?
        config.accounts.filter { |a| emails.include?(a.username) }
      else
        config.accounts
      end
    end

    private

    # Processes an ERB template and loads it as configuration
    # @raise [ConfigurationNotFound] if the ERB file does not exist
    # @raise [RuntimeError] if ERB processing fails
    # @raise [RuntimeError] if rendered output is invalid JSON
    # @return [Configuration]
    def load_erb_config(erb_path, _options)
      # Check if file exists
      unless File.exist?(erb_path)
        raise ConfigurationNotFound, I18n.t("cli.helpers.erb_config_not_found", path: erb_path)
      end

      begin
        # Read and process ERB template
        erb_content = File.read(erb_path)
        erb = ERB.new(erb_content)
        rendered_json = erb.result
      rescue SyntaxError => e
        raise I18n.t("cli.helpers.erb_syntax_error", message: e.message)
      rescue StandardError => e
        raise I18n.t("cli.helpers.erb_processing_error", message: e.message)
      end

      # Validate rendered JSON
      begin
        JSON.parse(rendered_json)
      rescue JSON::ParserError => e
        raise I18n.t("cli.helpers.erb_invalid_json", message: e.message)
      end

      # Create temporary file with rendered JSON
      temp_file = Tempfile.new(["config", ".json"])
      begin
        temp_file.write(rendered_json)
        temp_file.flush
        temp_file.close

        # Load configuration from temporary file
        config = Configuration.new(path: temp_file.path)
        # Force loading of data before temp file is deleted
        config.accounts
        config
      ensure
        # Clean up temporary file
        temp_file&.unlink
      end
    end
  end
end
