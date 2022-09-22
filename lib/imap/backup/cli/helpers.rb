require "imap/backup"

module Imap::Backup
  module CLI::Helpers
    def self.included(base)
      base.class_eval do
        def self.config_option
          method_option(
            "config",
            type: :string,
            desc: "supply the configuration file path (default: ~/.imap-backup/config.json)",
            aliases: ["-c"]
          )
        end

        def self.quiet_option
          method_option(
            "quiet",
            type: :boolean,
            desc: "silence all output",
            aliases: ["-q"]
          )
        end

        def self.verbose_option
          method_option(
            "verbose",
            type: :boolean,
            desc: "increase the amount of logging",
            aliases: ["-v"]
          )
        end
      end
    end

    def options
      @symbolized_options ||=
        begin
          options = super()
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

    def load_config(**options)
      path = options[:config]
      require_exists = options.key?(:require_exists) ? options[:require_exists] : true
      if require_exists
        exists = Configuration.exist?(path: path)
        if !exists
          expected = path || Configuration.default_pathname
          raise ConfigurationNotFound, "Configuration file '#{expected}' not found"
        end
      end
      Configuration.new(path: path)
    end

    def account(config, email)
      account = config.accounts.find { |a| a.username == email }
      raise "#{email} is not a configured account" if !account

      account
    end

    def connection(config, email)
      account = account(config, email)

      Account::Connection.new(account)
    end

    def each_connection(config, names)
      config.accounts.each do |account|
        next if names.any? && !names.include?(account.username)

        yield account.connection
      end
    rescue ConfigurationNotFound
      raise "imap-backup is not configured. Run `imap-backup setup`"
    end
  end
end
