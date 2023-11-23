module Imap; end

module Imap::Backup
  # @private
  MAJOR    = 14
  # @private
  MINOR    = 4
  # @private
  REVISION = 4
  # @private
  PRE      = nil
  # The application version
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
