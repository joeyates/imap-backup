require "json"

module Imap::Backup
  class Serializer::Imap
    CURRENT_VERSION = 2

    attr_reader :folder_path
    attr_reader :loaded

    def initialize(folder_path)
      @folder_path = folder_path
      @loaded = false
      @uid_validity = nil
      @uids = nil
    end

    def append(uid)
      uids << uid
      save
    end

    def exist?
      File.exist?(pathname)
    end

    def include?(uid)
      uids.include?(uid)
    end

    def index(uid)
      uids.find_index(uid)
    end

    def rename(new_path)
      if exist?
        old_pathname = pathname
        @folder_path = new_path
        File.rename(old_pathname, pathname)
      else
        @folder_path = new_path
      end
    end

    def uid_validity
      ensure_loaded
      @uid_validity
    end

    def uid_validity=(value)
      ensure_loaded
      @uid_validity = value
      @uids ||= []
      save
    end

    def uids
      ensure_loaded
      @uids || []
    end

    def update_uid(old, new)
      index = uids.find_index(old.to_i)
      return if index.nil?

      uids[index] = new.to_i
      save
    end

    private

    def pathname
      "#{folder_path}.imap"
    end

    def ensure_loaded
      return if loaded

      data = load
      if data
        @uids = data[:uids].map(&:to_i)
        @uid_validity = data[:uid_validity]
      else
        @uids = []
        @uid_validity = nil
      end
      @loaded = true
    end

    def load
      return nil if !exist?

      data = nil
      begin
        content = File.read(pathname)
        data = JSON.parse(content, symbolize_names: true)
      rescue JSON::ParserError
        return nil
      end

      return nil if !data.key?(:uids)
      return nil if !data[:uids].is_a?(Array)

      data
    end

    def save
      ensure_loaded

      raise "Cannot save metadata without a uid_validity" if !uid_validity

      data = {
        version: CURRENT_VERSION,
        uid_validity: @uid_validity,
        uids: @uids
      }
      content = data.to_json
      File.open(pathname, "w") { |f| f.write content }
    end
  end
end
