module Imap::Backup
  class Uploader
    attr_reader :folder
    attr_reader :serializer

    def initialize(folder, serializer)
      @folder = folder
      @serializer = serializer
    end

    def run
      missing_uids.each do |uid|
        message = serializer.load(uid)
        next if message.nil?
        new_uid = folder.append(message)
        serializer.update_uid(uid, new_uid)
      end
    end

    private

    def missing_uids
      serializer.uids - folder.uids
    end
  end
end
