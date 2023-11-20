require "imap/backup/email/provider/base"

module Imap; end

module Imap::Backup
  # Provides overrides for Fastmail accounts
  class Email::Provider::Fastmail < Email::Provider::Base
    def host
      "imap.fastmail.com"
    end
  end
end
