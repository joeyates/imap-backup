# encoding: utf-8

module Imap::Backup
  module Account; end

  class Account::Folder
    REQUESTED_ATTRIBUTES = ['RFC822', 'FLAGS', 'INTERNALDATE']

    attr_reader :connection
    attr_reader :folder

    def initialize(connection, folder)
      @connection, @folder = connection, folder
    end

    def uids
      connection.imap.examine(folder)
      connection.imap.uid_search(['ALL']).sort
    rescue Net::IMAP::NoResponseError => e
      Imap::Backup.logger.warn "Folder '#{folder}' does not exist"
      []
    end

    def fetch(uid)
      connection.imap.examine(folder)
      message = connection.imap.uid_fetch([uid.to_i], REQUESTED_ATTRIBUTES)[0][1]
      message['RFC822'].force_encoding('utf-8') if RUBY_VERSION > '1.9'
      message
    rescue Net::IMAP::NoResponseError => e
      Imap::Backup.logger.warn "Folder '#{folder}' does not exist"
      nil
    end
  end
end
