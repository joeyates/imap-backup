require "thor"

require "imap/backup/account"
require "imap/backup/account/backup"
require "imap/backup/configuration"

module Imap; end

module Imap::Backup
  class CLI < Thor; end
  class CLI::Single < Thor; end

  # Runs a backup without relying on existing configuration
  class CLI::Single::Backup
    def initialize(options)
      @options = options
      @password = nil
    end

    def run
      process_options!
      account = Account.new(
        username: email,
        password: password,
        server: server,
        download_strategy: download_strategy,
        folder_blacklist: folder_blacklist,
        local_path: local_path,
        mirror: mirror,
        reset_seen_flags_after_fetch: reset_seen_flags_after_fetch
      )
      account.connection_options = connection_options if connection_options
      account.folders = folders if folders.any?
      account.multi_fetch_size = multi_fetch_size if multi_fetch_size
      backup = Account::Backup.new(account: account, refresh: refresh)
      backup.run
    end

    private

    attr_reader :options
    attr_reader :password

    def process_options!
      if !email
        raise Thor::RequiredArgumentMissingError,
              "No value provided for required options '--email'"
      end
      if !server
        raise Thor::RequiredArgumentMissingError,
              "No value provided for required options '--server'"
      end
      handle_password_options!
    end

    def handle_password_options!
      plain = options[:password]
      env = options[:password_environment_variable]
      file = options[:password_file]
      case [plain, env, file]
      when [nil, nil, nil]
        raise Thor::RequiredArgumentMissingError,
              "Supply one of the --password... parameters"
      when [plain, nil, nil]
        @password = plain
      when [nil, env, nil]
        @password = ENV.fetch(env)
      when [nil, nil, file]
        @password = File.read(file).gsub(/\n$/, "")
      else
        raise ArgumentError, "Supply only one of the --password... parameters"
      end
    end

    def connection_options
      options[:connection_options]
    end

    def download_strategy
      @download_strategy =
        case options[:download_strategy]
        when nil
          Configuration::DEFAULT_STRATEGY
        when "delay"
          "delay_metadata"
        when "direct"
          "direct"
        else
          raise ArgumentError, "Unknown download_strategy: '#{options[:download_strategy]}'"
        end
    end

    def email
      options[:email]
    end

    def folder_blacklist
      options[:folder_blacklist] ? true : false
    end

    def folders
      @folders ||= options[:folder] || []
    end

    def local_path
      return options[:path] if options.key?(:path)

      for_account = email.tr("@", "_")
      File.join(Dir.pwd, for_account)
    end

    def mirror
      options[:mirror] ? true : false
    end

    def multi_fetch_size
      options[:multi_fetch_size]
    end

    def refresh
      options[:refresh] ? true : false
    end

    def reset_seen_flags_after_fetch
      options[:reset_seen_flags_after_fetch] ? true : false
    end

    def server
      options[:server]
    end
  end
end
