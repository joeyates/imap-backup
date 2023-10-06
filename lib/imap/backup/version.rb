module Imap; end

module Imap::Backup
  MAJOR    = 13
  MINOR    = 2
  REVISION = 0
  PRE      = nil
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
