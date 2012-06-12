module Imap
  module Backup
    MAJOR    = 0
    MINOR    = 0
    REVISION = 3
    VERSION  = [ MAJOR, MINOR, REVISION ].map( &:to_s ).join( '.' )
  end
end

