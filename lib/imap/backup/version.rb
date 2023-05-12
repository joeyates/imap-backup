module Imap; end

module Imap::Backup
  MAJOR    = 9
  MINOR    = 3
  REVISION = 1
  PRE      = nil
  VERSION  = [MAJOR, MINOR, REVISION, PRE].compact.map(&:to_s).join(".")
end
