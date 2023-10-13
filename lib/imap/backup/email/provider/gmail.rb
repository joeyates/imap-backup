require "imap/backup/email/provider/base"

module Imap; end

module Imap::Backup
  class Email::Provider::GMail < Email::Provider::Base
    def host
      "imap.gmail.com"
    end
  end
end
