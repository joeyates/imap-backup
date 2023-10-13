require "imap/backup/email/provider/base"

module Imap; end

module Imap::Backup
  class Email::Provider::AppleMail < Email::Provider::Base
    def host
      "imap.mail.me.com"
    end

    def sets_seen_flags_on_fetch?
      true
    end
  end
end
