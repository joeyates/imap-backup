require "json"

require "imap/backup/serializer/mbox_enumerator"

module Imap::Backup
  class Serializer::Version2Migrator
    attr_reader :folder_path

    def initialize(folder_path)
      @folder_path = folder_path
    end

    def run
      return false if !mbox_exists?
      return false if !imap_exists?
      return false if !data
      return false if data[:version] != 2
      return false if !data[:uid_validity]
      return false if !uids.is_a?(Array)

      messages = message_uids_and_lengths

      return false if !messages

      imap.delete
      imap.uid_validity = data[:uid_validity]
      messages.map { |m| imap.append(m[:uid], m[:length]) }

      true
    end

    private

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

    def data
      @data ||=
        begin
          content = File.read(imap_pathname)
          JSON.parse(content, symbolize_names: true)
        rescue JSON::ParserError
          nil
        end
    end

    def uids
      data[:uids]
    end

    def message_uids_and_lengths
      enumerator = Serializer::MboxEnumerator.new(mbox_pathname)
      messages = enumerator.map.with_index do |raw, i|
        length = raw.length
        message = {
          uid: uids[i],
          length: length
        }
        message
      end

      return nil if messages.count != uids.count

      messages
    end

    def imap
      @imap ||= Serializer::Imap.new(folder_path)
    end
  end
end
