require 'json'

module Imap
  module Backup

    class Settings

      include Imap::Backup::Utils

      attr_reader :accounts

      def initialize(accounts = nil)
        config_pathname = File.expand_path('~/.imap-backup/config.json')
        raise "Configuration file '#{config_pathname}' not found" if ! File.exist?(config_pathname)
        check_permissions(config_pathname, 0600)
        @settings = JSON.parse(File.read(config_pathname), :symbolize_names => true)
        if accounts.nil?
          @accounts = @settings[:accounts]
        else
          @accounts = @settings[:accounts].select{ |account| accounts.include?(account[:username]) }
        end
      end

      def each_connection
        @accounts.each do |account|
          connection = Imap::Backup::Account::Connection.new(account)
          yield connection
          connection.disconnect
        end
      end

      def run_backup
        @accounts.each do |account|
          connection = Imap::Backup::Account::Connection.new(account)
          account[:folders].each do |folder|
            f = Imap::Backup::Account::Folder.new(connection, folder[:name])
            s = Imap::Backup::Serializer::Directory.new(account[:local_path], folder[:name])
            d = Imap::Backup::Downloader.new(f, s)
            d.run
          end
          connection.disconnect
        end
      end

    end
  end
end

