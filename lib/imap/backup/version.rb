module Imap; end

module Imap::Backup
  # @private
  MAJOR    = 15
  # @private
  MINOR    = 0
  # @private
  REVISION = 3
  # @private
  PRE      = "rc1".freeze
  # The application version
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
