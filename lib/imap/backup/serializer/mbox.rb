# encoding: utf-8
require 'csv'
require 'email/mboxrd/message'

module Imap::Backup
  module Serializer; end

  class Serializer::Mbox < Serializer::Base
    def initialize(path, folder)
      super
      create_containing_directory
      assert_files
    end

    # TODO: cleanup locks, close file handles

    def uids
      return @uids if @uids

      @uids = []
      return @uids if not exist?

      CSV.foreach(imap_pathname) do |row|
        @uids << row[0]
      end
      @uids
    end

    def save(uid, message)
      uid = uid.to_s
      return if uids.include?(uid)
      body = message['RFC822']
      mboxrd_message = Email::Mboxrd::Message.new(body)
      mbox = imap = nil
      begin
        mbox = File.open(mbox_pathname, 'ab')
        imap = File.open(imap_pathname, 'ab')
        mbox.write mboxrd_message.to_s
        imap.write uid + "\n"
      rescue ArgumentError => e
        Imap::Backup.logger.warn "Failed to save message #{uid}:\n#{body}. #{e}"
      ensure
        mbox.close if mbox
        imap.close if imap
      end
    end

    private

    def assert_files
      mbox = mbox_exist?
      imap = imap_exist?
      raise '.imap file missing' if mbox and not imap
      raise '.mbox file missing' if imap and not mbox
    end

    def create_containing_directory
      mbox_relative_path = File.dirname(mbox_relative_pathname)
      return if mbox_relative_path == '.'
      Utils.make_folder(@path, mbox_relative_path, Serializer::DIRECTORY_PERMISSIONS)
    end

    def exist?
      mbox_exist? and imap_exist?
    end

    def mbox_exist?
      File.exist?(mbox_pathname)
    end

    def imap_exist?
      File.exist?(imap_pathname)
    end

    def mbox_relative_pathname
      @folder + '.mbox'
    end

    def mbox_pathname
      File.join(@path, mbox_relative_pathname)
    end

    def imap_pathname
      filename = @folder + '.imap'
      File.join(@path, filename)
    end

    def lock
      # lock mbox and imap files
      # create both empty if missing
    end

    def unlock
    end
  end
end
