module Imap; end

module Imap::Backup
  class FileMode
    attr_reader :filename

    def initialize(filename:)
      @filename = filename
    end

    def mode
      return nil if !File.exist?(filename)

      stat = File.stat(filename)
      stat.mode & 0o777
    end
  end
end
