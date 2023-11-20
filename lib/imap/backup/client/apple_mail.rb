require "imap/backup/client/default"

module Imap; end

module Imap::Backup
  # Overrides default IMAP client behaviour for Apple Mail accounts
  class Client::AppleMail < Client::Default
    # With Apple Mails's IMAP, passing "/" to list
    # results in an empty list
    def provider_root
      ""
    end
  end
end
