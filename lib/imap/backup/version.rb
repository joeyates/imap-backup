module Imap
  module Backup
    MAJOR    = 1
    MINOR    = 0
    REVISION = 8
    VERSION  = [MAJOR, MINOR, REVISION].map(&:to_s).join('.')
  end
end
