require "imap/backup/version"

module Imap::Backup
  class Setup; end

  class Setup::Helpers
    def title_prefix
      "imap-backup –"
    end

    def version
      VERSION
    end
  end
end
