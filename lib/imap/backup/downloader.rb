require 'json'

module Imap
  module Backup
    class Downloader

      def initialize(folder, serializer)
        @folder, @serializer = folder, serializer
      end

      def status
        {:local => @serializer.uids, :remote => @folder.uids}
      end

      def run
        @folder.uids.each do |uid|
          next if @serializer.exist?(uid)

          message = @folder.fetch(uid)

          @serializer.save(uid, message)
        end
      end

    end
  end
end

