require "imap/backup/version"

module Imap; end

module Imap::Backup
  class Setup; end

  # Helpers for the setup system
  class Setup::Helpers
    # The prefix for setup menus
    def title_prefix
      "imap-backup -"
    end

    # The current application version
    def version
      VERSION
    end
  end
end
