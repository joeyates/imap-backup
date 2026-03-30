module Imap; end

module Imap::Backup
  # @private
  MAJOR    = 17
  # @private
  MINOR    = 0
  # @private
  REVISION = 0
  # @private
  PRE      = "rc0"
  # The application version
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
