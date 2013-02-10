# encoding: utf-8

module Imap
  module Backup
    module Account
      class Folder
        REQUESTED_ATTRIBUTES = ['RFC822', 'FLAGS', 'INTERNALDATE']

        def initialize(connection, folder)
          @connection, @folder = connection, folder
        end

        def uids
          @connection.imap.examine(@folder)
          @connection.imap.uid_search(['ALL']).sort
        rescue Net::IMAP::NoResponseError => e
          warn "Folder '#{@folder}' does not exist"
          []
        end

        def fetch(uid)
          @connection.imap.examine(@folder)
          message = @connection.imap.uid_fetch([uid.to_i], REQUESTED_ATTRIBUTES)[0][1]
          message['RFC822'].force_encoding('utf-8') if RUBY_VERSION > '1.9'
          message
        end
      end
    end
  end
end

