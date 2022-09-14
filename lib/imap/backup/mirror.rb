module Imap::Backup
  class Mirror
    attr_reader :serializer
    attr_reader :folder

    def initialize(serializer, folder)
      @serializer = serializer
      @folder = folder
    end

    def run
    end
  end
end
