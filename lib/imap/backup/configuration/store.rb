# encoding: utf-8
require 'rubygems' if RUBY_VERSION < '1.9'
require 'json'

module Imap::Backup
  module Configuration; end

  class Configuration::Store
    CONFIGURATION_DIRECTORY = File.expand_path('~/.imap-backup')

    attr_reader :pathname

    def self.default_pathname
      File.join(CONFIGURATION_DIRECTORY, 'config.json')
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
      if File.directory?(path)
        Utils.check_permissions path, 0700
      end
      mkdir_private path
      File.open(pathname, 'w') { |f| f.write(JSON.pretty_generate(data)) }
      FileUtils.chmod 0600, pathname
      accounts.each do |account|
        mkdir_private account[:local_path]
        account[:folders].each do |f|
          parts = f[:name].split('/')
          p     = account[:local_path].clone
          parts.each do |part|
            p    = File.join(p, part)
            mkdir_private p
          end
        end
      end
    end

    def accounts
      data[:accounts]
    end

    def debug?
      data.include?(:debug)
    end

    private

    def data
      return @data if @data
      if File.exist?(pathname)
        Utils.check_permissions pathname, 0600
        @data = JSON.parse(File.read(pathname), :symbolize_names => true)
      else
        @data = {:accounts => []}
      end
    end

    def mkdir_private(path)
      if ! File.directory?(path)
        FileUtils.mkdir path
      end
      if Utils::stat(path) != 0700
        FileUtils.chmod 0700, path
      end
    end
  end
end
