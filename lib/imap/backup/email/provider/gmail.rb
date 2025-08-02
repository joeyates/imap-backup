require "imap/backup/email/provider/base"

module Imap; end

module Imap::Backup
  # Provides overrides for GMail accounts
  class Email::Provider::GMail < Email::Provider::Base
    # https://imap-use.u.washington.narkive.com/RYMsOHTN/imap-protocol-status-on-a-noselect-mailbox
    def folder_ignore_tags
      [:Noselect]
    end

    # @return [String] the GMail IMAP server host name
    def host
      "imap.gmail.com"
    end
  end
end
