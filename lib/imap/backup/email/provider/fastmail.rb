require "imap/backup/email/provider/base"

module Imap; end

module Imap::Backup
  # Provides overrides for Fastmail accounts
  class Email::Provider::Fastmail < Email::Provider::Base
    # @return [String] the Fastmail IMAP server host name
    def host
      "imap.fastmail.com"
    end
  end
end
