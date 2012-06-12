# encoding: utf-8
require 'rubygems' if RUBY_VERSION < '1.9'
require 'json'

module Imap
  module Backup
    class Downloader

      def initialize(folder, serializer)
        @folder, @serializer = folder, serializer
      end

      def run
        uids = @folder.uids - @serializer.uids
        uids.each do |uid|
          message = @folder.fetch(uid)
          @serializer.save(uid, message)
        end
      end

    end
  end
end

