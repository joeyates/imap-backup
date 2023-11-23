require "imap/backup/email/provider/base"

module Imap; end

module Imap::Backup
  # Provides overrides for Apple mail accounts
  class Email::Provider::AppleMail < Email::Provider::Base
    # @return [String] the Apple Mail IMAP server host name
    def host
      "imap.mail.me.com"
    end

    def sets_seen_flags_on_fetch?
      true
    end
  end
end
