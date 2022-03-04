module Imap; end

module Imap::Backup
  MAJOR    = 6
  MINOR    = 0
  REVISION = 0
  PRE      = "rc2".freeze
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
