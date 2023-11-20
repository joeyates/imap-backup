module Imap; end

module Imap::Backup
  # Accesses a file's access premissions
  class FileMode
    def initialize(filename:)
      @filename = filename
    end

    def mode
      return nil if !File.exist?(filename)

      stat = File.stat(filename)
      stat.mode & 0o777
    end

    private

    attr_reader :filename
  end
end
