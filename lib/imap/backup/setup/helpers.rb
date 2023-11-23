require "imap/backup/version"

module Imap; end

module Imap::Backup
  class Setup; end

  # Helpers for the setup system
  class Setup::Helpers
    # @return [String] the prefix for setup menus
    def title_prefix
      "imap-backup -"
    end

    # @return [String] the current application version
    def version
      VERSION
    end
  end
end
