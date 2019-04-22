module Imap; end

module Imap::Backup
  MAJOR    = 2
  MINOR    = 1
  REVISION = 0
  VERSION  = [MAJOR, MINOR, REVISION].compact.map(&:to_s).join(".")
end
