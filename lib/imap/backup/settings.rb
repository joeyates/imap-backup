require 'json'

module Imap
  module Backup

    class Settings

      include Imap::Backup::Utils

      def initialize
        config_pathname = File.expand_path('~/.imap-backup/config.json')
        raise "Configuration file '#{config_pathname}' not found" if ! File.exist?(config_pathname)
        check_permissions(config_pathname, 0600)
        @settings = JSON.load(File.open(config_pathname))
      end

      def each_account
        @settings['accounts'].each do |account|
          a = Account.new(account)
          yield a
          a.disconnect
        end
      end

    end
  end
end

