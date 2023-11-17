require "fileutils"
require "json"
require "os"

require "imap/backup/account"
require "imap/backup/file_mode"
require "imap/backup/serializer/permission_checker"

module Imap; end

module Imap::Backup
  class Configuration
    CONFIGURATION_DIRECTORY = File.expand_path("~/.imap-backup")
    DEFAULT_STRATEGY = "delay_metadata".freeze
    DOWNLOAD_STRATEGIES = [
      {key: "direct", description: "write straight to disk"},
      {key: DEFAULT_STRATEGY, description: "delay writing metadata"}
    ].freeze
    VERSION = "2.2".freeze

    def self.default_pathname
      File.join(CONFIGURATION_DIRECTORY, "config.json")
    end

    def self.exist?(path: nil)
      File.exist?(path || default_pathname)
    end

    def initialize(path: nil)
      @pathname = path || self.class.default_pathname
      @download_strategy = nil
      @download_strategy_original = nil
      @download_strategy_modified = false
    end

    def path
      File.dirname(pathname)
    end

    def save
      ensure_loaded!
      FileUtils.mkdir_p(path) if !File.directory?(path)
      make_private(path) if !windows?
      remove_modified_flags
      remove_deleted_accounts
      save_data = {
        version: VERSION,
        accounts: accounts.map(&:to_h),
        download_strategy: download_strategy
      }
      File.open(pathname, "w") { |f| f.write(JSON.pretty_generate(save_data)) }
      FileUtils.chmod(0o600, pathname) if !windows?
      @data = nil
    end

    def accounts
      @accounts ||= begin
        ensure_loaded!
        accounts = data[:accounts].map do |attr|
          Account.new(attr)
        end
        inject_global_attributes(accounts)
      end
    end

    def download_strategy
      ensure_loaded!

      @download_strategy
    end

    def download_strategy=(value)
      raise "Unknown strategy '#{value}'" if !DOWNLOAD_STRATEGIES.find { |s| s[:key] == value }

      ensure_loaded!

      @download_strategy = value
      @download_strategy_modified = value != @download_strategy_original
      inject_global_attributes(accounts)
    end

    def download_strategy_modified?
      ensure_loaded!

      @download_strategy_modified
    end

    def modified?
      ensure_loaded!

      return true if download_strategy_modified?

      accounts.any? { |a| a.modified? || a.marked_for_deletion? }
    end

    private

    VERSION_2_1 = "2.1".freeze

    attr_reader :pathname

    def ensure_loaded!
      return true if @data

      data
      @download_strategy = data[:download_strategy]
      @download_strategy_original = data[:download_strategy]
      true
    end

    def data
      @data ||=
        if File.exist?(pathname)
          permission_checker = Serializer::PermissionChecker.new(
            filename: pathname, limit: 0o600
          )
          permission_checker.run if !windows?
          contents = File.read(pathname)
          data = JSON.parse(contents, symbolize_names: true)
          data[:download_strategy] =
            if DOWNLOAD_STRATEGIES.find { |s| s[:key] == data[:download_strategy] }
              data[:download_strategy]
            else
              DEFAULT_STRATEGY
            end
          dehashify_folders(data)
        else
          {accounts: [], download_strategy: DEFAULT_STRATEGY}
        end
    end

    def dehashify_folders(data)
      data[:accounts].each do |account|
        next if !account.key?(:folders)

        folders = account[:folders]
        names = folders.map do |f|
          case f
          when Hash
            f[:name]
          else
            f
          end
        end
        account[:folders] = names
      end

      data[:version] = VERSION

      data
    end

    def remove_modified_flags
      @download_strategy_modified = false
      accounts.each(&:clear_changes)
    end

    def remove_deleted_accounts
      accounts.reject!(&:marked_for_deletion?)
    end

    def inject_global_attributes(accounts)
      accounts.map do |a|
        a.download_strategy = download_strategy
        a
      end
    end

    def make_private(path)
      FileUtils.chmod(0o700, path) if FileMode.new(filename: path).mode != 0o700
    end

    def windows?
      OS.windows?
    end
  end
end
