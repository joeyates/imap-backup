module Imap; end

module Imap::Backup
  MAJOR    = 11
  MINOR    = 1
  REVISION = 0
  PRE      = "rc1".freeze
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
