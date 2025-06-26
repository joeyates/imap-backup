module Imap; end

module Imap::Backup
  # @private
  MAJOR    = 15
  # @private
  MINOR    = 1
  # @private
  REVISION = 3
  # @private
  PRE      = nil
  # The application version
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
