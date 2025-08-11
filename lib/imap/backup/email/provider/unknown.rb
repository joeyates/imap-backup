require "imap/backup/email/provider/base"

module Imap; end

module Imap::Backup
  # Provides overrides when the IMAP provider is not known
  class Email::Provider::Unknown < Email::Provider::Base
    # We don't know how to guess the IMAP server
    # @return [nil]
    def host
    end
  end
end
