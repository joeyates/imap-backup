module Imap; end

module Imap::Backup
  # Accesses a file's access permissions
  class FileMode
    def initialize(filename:)
      @filename = filename
    end

    # @return [Integer, nil] The user, group and "other" part of the file's "mode"
    def mode
      return nil if !File.exist?(filename)

      stat = File.stat(filename)
      stat.mode & 0o777
    end

    private

    attr_reader :filename
  end
end
