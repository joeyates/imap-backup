require "forwardable"

require "email/mboxrd/message"
require "imap/backup/serializer/appender"
require "imap/backup/serializer/imap"
require "imap/backup/serializer/mbox"
require "imap/backup/serializer/mbox_enumerator"

module Imap::Backup
  class Serializer
    extend Forwardable

    def_delegator :mbox, :pathname, :mbox_pathname
    def_delegators :imap, :uid_validity, :uids, :update_uid

    attr_reader :folder
    attr_reader :path

    def initialize(path, folder)
      @path = path
      @folder = folder
    end

    def apply_uid_validity(value)
      case
      when uid_validity.nil?
        imap.uid_validity = value
        nil
      when uid_validity == value
        # NOOP
        nil
      else
        apply_new_uid_validity value
      end
    end

    def force_uid_validity(value)
      imap.uid_validity = value
    end

    def append(uid, message)
      appender = Serializer::Appender.new(folder: folder, imap: imap, mbox: mbox)
      appender.run(uid: uid, message: message)
    end

    def load(uid_maybe_string)
      uid = uid_maybe_string.to_i
      message_index = imap.index(uid)
      return nil if message_index.nil?

      load_nth(message_index)
    end

    def load_nth(index)
      enumerator = Serializer::MboxEnumerator.new(mbox.pathname)
      enumerator.each.with_index do |raw, i|
        next if i != index

        return Email::Mboxrd::Message.from_serialized(raw)
      end
      nil
    end

    def each_message(required_uids)
      return enum_for(:each_message, required_uids) if !block_given?

      indexes = required_uids.each.with_object({}) do |uid_maybe_string, acc|
        uid = uid_maybe_string.to_i
        index = imap.index(uid)
        acc[index] = uid if index
      end
      enumerator = Serializer::MboxEnumerator.new(mbox.pathname)
      enumerator.each.with_index do |raw, i|
        uid = indexes[i]
        next if !uid

        yield uid, Email::Mboxrd::Message.from_serialized(raw)
      end
    end

    def rename(new_name)
      destination = folder_path_for(path, new_name)
      ensure_containing_directory(new_name)
      mbox.rename destination
      imap.rename destination
    end

    private

    def mbox
      @mbox ||=
        begin
          ensure_containing_directory(folder)
          Serializer::Mbox.new(folder_path)
        end
    end

    def imap
      @imap ||=
        begin
          ensure_containing_directory(folder)
          Serializer::Imap.new(folder_path)
        end
    end

    def folder_path
      folder_path_for(path, folder)
    end

    def folder_path_for(path, folder)
      relative = File.join(path, folder)
      File.expand_path(relative)
    end

    def ensure_containing_directory(folder)
      relative = File.dirname(folder)
      directory = Serializer::Directory.new(path, relative)
      directory.ensure_exists
    end

    def apply_new_uid_validity(value)
      new_name = rename_existing_folder
      # Clear memoization so we get empty data
      @mbox = nil
      @imap = nil
      imap.uid_validity = value

      new_name
    end

    def rename_existing_folder
      digit = 0
      new_name = nil
      loop do
        extra = digit.zero? ? "" : "-#{digit}"
        new_name = "#{folder}-#{imap.uid_validity}#{extra}"
        new_folder_path = folder_path_for(path, new_name)
        test_mbox = Serializer::Mbox.new(new_folder_path)
        test_imap = Serializer::Imap.new(new_folder_path)
        break if !test_mbox.exist? && !test_imap.exist?

        digit += 1
      end

      rename new_name

      new_name
    end
  end
end
