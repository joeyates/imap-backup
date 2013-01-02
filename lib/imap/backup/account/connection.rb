require 'net/imap'

module Imap
  module Backup
    module Account
      class Connection
        attr_reader :username
        attr_reader :imap

        def initialize(options)
          @username = options[:username]
          @local_path, @backup_folders = options[:local_path], options[:folders]
          @imap = Net::IMAP.new(options[:server] || 'imap.gmail.com', 993, true)
          @imap.login(@username, options[:password])
        end

        def disconnect
          @imap.disconnect
        end

        def folders
          @imap.list('/', '*')
        end

        def status
          @backup_folders.map do |folder|
            f = Imap::Backup::Account::Folder.new(self, folder[:name])
            s = Imap::Backup::Serializer::Directory.new(@local_path, folder[:name])
            {:name => folder[:name], :local => s.uids, :remote => f.uids}
          end
        end

        def run_backup
          @backup_folders.each do |folder|
            f = Imap::Backup::Account::Folder.new(self, folder[:name])
            s = Imap::Backup::Serializer::Directory.new(@local_path, folder[:name])
            d = Imap::Backup::Downloader.new(f, s)
            d.run
          end
        end
      end
    end
  end
end

