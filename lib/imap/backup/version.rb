module Imap; end

module Imap::Backup
  MAJOR    = 2
  MINOR    = 0
  REVISION = 0
  PRE      = "rc1"
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
