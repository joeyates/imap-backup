module Imap; end

module Imap::Backup
  # Thrown when no configuration file is found
  class ConfigurationNotFound < StandardError; end
end
