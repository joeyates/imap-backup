require "imap/backup/email/provider/base"

module Imap; end

module Imap::Backup
  # Provides overrides for Purelymail accounts
  class Email::Provider::Purelymail < Email::Provider::Base
    # @return [String] The Purelymail IMAP server host name
    def host
      "mailserver.purelymail.com"
    end

    def sets_seen_flags_on_fetch?
      true
    end
  end
end
