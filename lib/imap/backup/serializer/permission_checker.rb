require "imap/backup/file_mode"

module Imap; end

module Imap::Backup
  # Ensures a file has the desired permissions
  class Serializer::PermissionChecker
    def initialize(filename:, limit:)
      @filename = filename
      @limit = limit
    end

    # Runs the check
    def run
      actual = FileMode.new(filename: filename).mode
      return nil if actual.nil?

      mask = ~limit & 0o777
      return if (actual & mask).zero?

      message = format(
        "Permissions on '%<filename>s' " \
        "should be 0%<limit>o, not 0%<actual>o",
        filename: filename, limit: limit, actual: actual
      )
      raise message
    end

    private

    attr_reader :filename
    attr_reader :limit
  end
end
