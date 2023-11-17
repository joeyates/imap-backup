require "json"

require "imap/backup/serializer/imap"

module Imap; end

module Imap::Backup
  class Serializer::Version2Migrator
    def initialize(folder_path)
      @folder_path = folder_path
    end

    def required?
      return false if !mbox_exists?
      return false if !imap_exists?
      return false if !imap_data
      return false if imap_data[:version] != 2
      return false if !imap_data[:uid_validity]
      return false if !uids.is_a?(Array)

      true
    end

    def run
      return false if !required?

      messages = message_uids_and_lengths

      return false if !messages

      imap.delete
      imap.uid_validity = imap_data[:uid_validity]
      messages.map { |m| imap.append(m[:uid], m[:length]) }

      true
    end

    private

    attr_reader :folder_path

    def imap_pathname
      "#{folder_path}.imap"
    end

    def imap_exists?
      File.exist?(imap_pathname)
    end

    def mbox_pathname
      "#{folder_path}.mbox"
    end

    def mbox_exists?
      File.exist?(mbox_pathname)
    end

    def imap_data
      @imap_data ||=
        begin
          content = File.read(imap_pathname)
          JSON.parse(content, symbolize_names: true)
        rescue JSON::ParserError
          nil
        end
    end

    def uids
      imap_data[:uids]
    end

    def message_uids_and_lengths
      messages = []

      File.open(mbox_pathname, "rb") do |f|
        lines = []

        loop do
          line = f.gets
          break if !line

          if line.start_with?("From ")
            if lines.any?
              message = {
                uid: uids[messages.count],
                length: lines.join.length
              }

              messages << message
            end

            lines = [line]
          else
            lines << line
          end
        end

        next if lines.count.zero?

        message = {
          uid: uids[messages.count],
          length: lines.join.length
        }

        messages << message
      end

      return nil if messages.count != uids.count

      messages
    end

    def imap
      @imap ||= Serializer::Imap.new(folder_path)
    end
  end
end
