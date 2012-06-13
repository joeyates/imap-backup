# encoding: utf-8
require 'rubygems' if RUBY_VERSION < '1.9'
require 'json'

module Imap
  module Backup
    class Configuration

      include Imap::Backup::Utils

      attr_reader :accounts

      def initialize(accounts = nil)
        config_pathname = File.expand_path('~/.imap-backup/config.json')
        if ! File.exist?(config_pathname)
          raise ConfigurationNotFound.new("Configuration file '#{config_pathname}' not found")
        end

        check_permissions(config_pathname, 0600)
        @configuration_data = JSON.parse(File.read(config_pathname), :symbolize_names => true)
        if accounts.nil?
          @accounts = @configuration_data[:accounts]
        else
          @accounts = @configuration_data[:accounts].select{ |account| accounts.include?(account[:username]) }
        end
      end

      def each_connection
        @accounts.each do |account|
          connection = Imap::Backup::Account::Connection.new(account)
          yield connection
          connection.disconnect
        end
      end

    end
  end
end

