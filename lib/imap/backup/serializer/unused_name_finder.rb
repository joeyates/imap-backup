require "imap/backup/serializer"

module Imap; end

module Imap::Backup
  class Serializer; end

  # Finds a name that can be used to rename a serialized folder
  class Serializer::UnusedNameFinder
    # @param serializer [Serializer] a folder serializer
    def initialize(serializer:)
      @serializer = serializer
    end

    # Finds the name
    # @return [String] the name
    def run
      digit = 0
      folder = nil

      loop do
        extra = digit.zero? ? "" : "-#{digit}"
        folder = "#{serializer.folder}-#{serializer.uid_validity}#{extra}"
        test = Serializer.new(serializer.path, folder)
        break if !test.validate!

        digit += 1
      end

      folder
    end

    private

    attr_reader :serializer
  end
end
