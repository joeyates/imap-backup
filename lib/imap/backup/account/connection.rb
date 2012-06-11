require 'net/imap'

module Imap
  module Backup
    module Account
      class Connection

        attr_reader   :username
        attr_reader   :imap
        attr_accessor :backup_folders

        def initialize(options)
          @username, @backup_folders = options[:username], options[:folders]
          @imap = Net::IMAP.new('imap.gmail.com', 993, true)
          @imap.login(@username, options[:password])
        end

        def disconnect
          @imap.disconnect
        end

        def folders
          @imap.list('/', '*')
        end

      end
    end
  end
end

