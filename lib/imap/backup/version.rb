module Imap; end

module Imap::Backup
  # @private
  MAJOR    = 15
  # @private
  MINOR    = 0
  # @private
  REVISION = 2
  # @private
  PRE      = nil
  # The application version
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
