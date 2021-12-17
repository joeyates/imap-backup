require "json"
require "os"

module Imap::Backup
  module Configuration; end

  class Configuration::Store
    CONFIGURATION_DIRECTORY = File.expand_path("~/.imap-backup")

    attr_reader :pathname

    def self.default_pathname
      File.join(CONFIGURATION_DIRECTORY, "config.json")
    end

    def self.exist?(pathname = default_pathname)
      File.exist?(pathname)
    end

    def initialize(pathname = self.class.default_pathname)
      @pathname = pathname
    end

    def path
      File.dirname(pathname)
    end

    def save
      FileUtils.mkdir(path) if !File.directory?(path)
      make_private(path) if !windows?
      remove_modified_flags
      remove_deleted_accounts
      File.open(pathname, "w") { |f| f.write(JSON.pretty_generate(data)) }
      FileUtils.chmod(0o600, pathname) if !windows?
    end

    def accounts
      data[:accounts]
    end

    def modified?
      accounts.any? { |a| a[:modified] || a[:delete] }
    end

    def debug?
      data[:debug]
    end

    def debug=(value)
      data[:debug] = [true, false].include?(value) ? value : false
    end

    private

    def data
      @data ||=
        begin
          if File.exist?(pathname)
            Utils.check_permissions(pathname, 0o600) if !windows?
            contents = File.read(pathname)
            data = JSON.parse(contents, symbolize_names: true)
          else
            data = {accounts: []}
          end
          data[:debug] = data.key?(:debug) ? data[:debug] == true : false
          data
        end
    end

    def remove_modified_flags
      accounts.each { |a| a.delete(:modified) }
    end

    def remove_deleted_accounts
      accounts.reject! { |a| a[:delete] }
    end

    def make_private(path)
      FileUtils.chmod(0o700, path) if Utils.mode(path) != 0o700
    end

    def windows?
      OS.windows?
    end
  end
end
