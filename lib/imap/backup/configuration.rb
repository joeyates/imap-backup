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
    VERSION = "2.0".freeze

    attr_reader :pathname

    def self.default_pathname
      File.join(CONFIGURATION_DIRECTORY, "config.json")
    end

    def self.exist?(path: nil)
      File.exist?(path || default_pathname)
    end

    def initialize(path: nil)
      @pathname = path || self.class.default_pathname
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
        accounts: accounts.map(&:to_h)
      }
      File.open(pathname, "w") { |f| f.write(JSON.pretty_generate(save_data)) }
      FileUtils.chmod(0o600, pathname) if !windows?
      @data = nil
    end

    def accounts
      @accounts ||= begin
        ensure_loaded!
        data[:accounts].map { |data| Account.new(data) }
      end
    end

    def modified?
      ensure_loaded!

      accounts.any? { |a| a.modified? || a.marked_for_deletion? }
    end

    private

    def ensure_loaded!
      return true if @data

      data
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
          JSON.parse(contents, symbolize_names: true)
        else
          {accounts: []}
        end
    end

    def remove_modified_flags
      accounts.each(&:clear_changes)
    end

    def remove_deleted_accounts
      accounts.reject!(&:marked_for_deletion?)
    end

    def make_private(path)
      FileUtils.chmod(0o700, path) if FileMode.new(filename: path).mode != 0o700
    end

    def windows?
      OS.windows?
    end
  end
end
