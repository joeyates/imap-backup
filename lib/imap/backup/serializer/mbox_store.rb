require "json"

require "email/mboxrd/message"

module Imap::Backup
  class Serializer::MboxStore
    CURRENT_VERSION = 1

    attr_reader :folder
    attr_reader :path

    def initialize(path, folder)
      @path = path
      @folder = folder
      @uids = nil
    end

    def add(uid, message)
      uid = uid.to_i
      if uids.include?(uid)
        Imap::Backup.logger.debug(
          "[#{folder}] message #{uid} already downloaded - skipping"
        )
        return
      end

      body = message["RFC822"]
      mboxrd_message = Email::Mboxrd::Message.new(body)
      mbox = nil
      begin
        mbox = File.open(mbox_pathname, "ab")
        mbox.write mboxrd_message.to_serialized
        @uids << uid
        write_imap_file
      rescue => e
        message = <<-ERROR.gsub(/^\s*/m, "")
          [#{folder}] failed to save message #{uid}:
          #{body}. #{e}:
          #{e.backtrace.join("\n")}"
        ERROR
        Imap::Backup.logger.warn message
      ensure
        mbox.close if mbox
      end
    end

    def load(uid)
      message_index = uids.find_index(uid)
      return nil if message_index.nil?
      load_nth(message_index)
    end

    def reset
      @uids = nil
      delete_files
      write_imap_file
      write_blank_mbox_file
    end

    def relative_path
      File.dirname(folder)
    end

    def uids
      @uids ||=
        begin
          data = imap_data
          if data
            imap_data[:uids].map(&:to_i).sort
          else
            reset
            []
          end
        end
    end

    private

    def imap_data
      if !imap_ok?
        return nil
      end

      imap_data = nil

      begin
        imap_data = JSON.parse(File.read(imap_pathname), symbolize_names: true)
      rescue JSON::ParserError
        return nil
      end

      return nil if imap_data[:version] != CURRENT_VERSION
      return nil if !imap_data.has_key?(:uids)
      return nil if !imap_data[:uids].is_a?(Array)

      imap_data
    end

    def imap_ok?
      return false if !exist?
      return false if !imap_looks_like_json?
      true
    end

    def load_nth(index)
      each_mbox_message.with_index do |raw, i|
        next unless i == index
        return Email::Mboxrd::Message.from_serialized(raw)
      end
      nil
    end

    def each_mbox_message
      Enumerator.new do |e|
        File.open(mbox_pathname) do |f|
          lines = []

          while line = f.gets
            if line.start_with?("From ")
              e.yield lines.join("\n") + "\n" if lines.count > 0
              lines = [line]
            else
              lines << line
            end
          end
          e.yield lines.join("\n") + "\n" if lines.count > 0
        end
      end
    end

    def imap_looks_like_json?
      return false unless imap_exist?
      content = File.read(imap_pathname)
      content.start_with?("{")
    end

    def write_imap_file
      imap_data = {
        version: CURRENT_VERSION,
        uids: @uids
      }
      content = imap_data.to_json
      File.open(imap_pathname, "w") { |f| f.write content }
    end

    def write_blank_mbox_file
      File.open(mbox_pathname, "w") { |f| f.write "" }
    end

    def delete_files
      File.unlink(imap_pathname) if imap_exist?
      File.unlink(mbox_pathname) if mbox_exist?
    end

    def exist?
      mbox_exist? && imap_exist?
    end

    def mbox_exist?
      File.exist?(mbox_pathname)
    end

    def imap_exist?
      File.exist?(imap_pathname)
    end

    def absolute_path(relative_path)
      File.join(path, relative_path)
    end

    def mbox_pathname
      absolute_path(folder + ".mbox")
    end

    def imap_pathname
      absolute_path(folder + ".imap")
    end
  end
end
