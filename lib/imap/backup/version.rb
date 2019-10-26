module Imap; end

module Imap::Backup
  MAJOR    = 2
  MINOR    = 2
  REVISION = 1
  VERSION  = [MAJOR, MINOR, REVISION].compact.map(&:to_s).join(".")
end
