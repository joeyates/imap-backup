require "imap/backup/version"

module Imap; end

module Imap::Backup
  class Setup; end

  class Setup::Helpers
    # Helpers for the setup system
    def title_prefix
      "imap-backup -"
    end

    def version
      VERSION
    end
  end
end
