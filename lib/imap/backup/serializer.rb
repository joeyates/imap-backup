require "forwardable"

require "email/mboxrd/message"
require "imap/backup/serializer/imap"
require "imap/backup/serializer/mbox"
require "imap/backup/serializer/mbox_enumerator"

module Imap::Backup
  class Serializer
    extend Forwardable

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
      raise "Can't add messages without uid_validity" if !imap.uid_validity

      uid = uid.to_i
      if imap.include?(uid)
        Logger.logger.debug(
          "[#{folder}] message #{uid} already downloaded - skipping"
        )
        return
      end

      do_append uid, message
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
      # Initialize so we get memoized instances with the correct folder_path
      mbox
      imap
      @folder = new_name
      ensure_containing_directory
      mbox.rename folder_path
      imap.rename folder_path
    end

    private

    def do_append(uid, message)
      mboxrd_message = Email::Mboxrd::Message.new(message)
      initial = mbox.length || 0
      mbox_appended = false
      begin
        mbox.append mboxrd_message.to_serialized
        mbox_appended = true
        imap.append uid
      rescue StandardError => e
        mbox.rewind(initial) if mbox_appended

        message = <<-ERROR.gsub(/^\s*/m, "")
          [#{folder}] failed to append message #{uid}:
          #{message}. #{e}:
          #{e.backtrace.join("\n")}"
        ERROR
        Logger.logger.warn message
      end
    end

    def mbox
      @mbox ||=
        begin
          ensure_containing_directory
          Serializer::Mbox.new(folder_path)
        end
    end

    def imap
      @imap ||=
        begin
          ensure_containing_directory
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

    def ensure_containing_directory
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

      previous = folder
      rename(new_name)
      @folder = previous

      new_name
    end
  end
end
