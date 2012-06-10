require 'net/imap'

module Imap
  module Backup
    class Account

      REQUESTED_ATTRIBUTES = ['RFC822', 'FLAGS', 'INTERNALDATE']

      attr_reader   :username
      attr_accessor :local_path
      attr_accessor :backup_folders

      def initialize(options)
        @username, @local_path, @backup_folders = options[:username], options[:local_path], options[:folders]
        @imap = Net::IMAP.new('imap.gmail.com', 993, true)
        @imap.login(@username, options[:password])
      end

      def disconnect
        @imap.disconnect
      end

      def folders
        @imap.list('/', '*')
      end

      def each_uid(folder)
        @imap.examine(folder)
        @imap.uid_search(['ALL']).each do |uid|
          yield uid
        end
      end

      def fetch(uid)
        message = @imap.uid_fetch([uid], REQUESTED_ATTRIBUTES)[0][1]
        message['RFC822'].force_encoding('utf-8') if RUBY_VERSION > '1.9'
        message
      end

    end
  end
end

