# encoding: utf-8
require 'fileutils'

module Imap::Backup
  module Serializer; end

  class Serializer::Directory < Serializer::Base
    def initialize(path, folder)
      super
      Utils.make_folder(@path, @folder, Serializer::DIRECTORY_PERMISSIONS)
    end

    def uids
      return [] if ! File.exist?(directory)

      d = Dir.open(directory)
      as_strings = d.map do |file|
        file[/^0*(\d+).json$/, 1]
      end.compact
      as_strings.map(&:to_i).sort
    end

    def exist?(uid)
      message_filename = filename(uid)
      File.exist?(message_filename)
    end

    def save(uid, message)
      message_filename = filename(uid)
      File.open(message_filename, 'w') { |f| f.write message.to_json }
      FileUtils.chmod 0600, message_filename
    end

    private

    def directory
      File.join(@path, @folder)
    end

    def filename(uid)
      "#{directory}/%012u.json" % uid.to_i
    end
  end
end
