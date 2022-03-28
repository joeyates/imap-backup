module Imap::Backup
  class Serializer::UnusedNameFinder
    attr_reader :serializer

    def initialize(serializer:)
      @serializer = serializer
    end

    def run
      digit = 0
      name = nil

      loop do
        extra = digit.zero? ? "" : "-#{digit}"
        name = "#{serializer.folder}-#{serializer.uid_validity}#{extra}"
        new_folder_path = Serializer.folder_path_for(path: serializer.path, folder: name)
        test_mbox = Serializer::Mbox.new(new_folder_path)
        test_imap = Serializer::Imap.new(new_folder_path)
        break if !test_mbox.exist? && !test_imap.exist?

        digit += 1
      end

      name
    end
  end
end
