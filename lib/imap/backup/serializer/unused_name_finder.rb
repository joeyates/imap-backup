require "imap/backup/serializer"

module Imap; end

module Imap::Backup
  class Serializer::UnusedNameFinder
    def initialize(serializer:)
      @serializer = serializer
    end

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
