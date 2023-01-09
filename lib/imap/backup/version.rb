module Imap; end

module Imap::Backup
  MAJOR    = 9
  MINOR    = 0
  REVISION = 2
  PRE      = nil
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
