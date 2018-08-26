require "imap/backup/serializer/mbox_store"

module Imap::Backup
  class Serializer::Mbox
    attr_reader :path
    attr_reader :folder

    def initialize(path, folder)
      @path = path
      @folder = folder
    end

    def set_uid_validity(value)
      existing_uid_validity = store.uid_validity
      case
      when existing_uid_validity.nil?
        store.uid_validity = value
        nil
      when existing_uid_validity == value
        # NOOP
        nil
      else
        digit = nil
        new_name = nil
        loop do
          extra = digit ? ".#{digit}" : ""
          new_name = "#{folder}.#{existing_uid_validity}#{extra}"
          test_store = Serializer::MboxStore.new(path, new_name)
          break if !test_store.exist?
          digit ||= 0
          digit += 1
        end
        store.rename new_name
        @store = nil
        store.uid_validity = value
        new_name
      end
    end

    def force_uid_validity(value)
      store.uid_validity = value
    end

    def uids
      store.uids
    end

    def load(uid)
      store.load(uid)
    end

    def save(uid, message)
      store.add(uid, message)
    end

    def rename(new_name)
      @folder = new_name
      store.rename new_name
    end

    def update_uid(old, new)
      store.update_uid old, new
    end

    private

    def store
      @store ||=
        begin
          create_containing_directory
          Serializer::MboxStore.new(path, folder)
        end
    end

    def create_containing_directory
      relative_path = File.dirname(folder)
      containing_directory = File.join(path, relative_path)
      full_path = File.expand_path(containing_directory)

      if !File.directory?(full_path)
        Imap::Backup::Utils.make_folder(
          path, relative_path, Serializer::DIRECTORY_PERMISSIONS
        )
      end

      if Imap::Backup::Utils.mode(full_path) !=
          Serializer::DIRECTORY_PERMISSIONS
        FileUtils.chmod Serializer::DIRECTORY_PERMISSIONS, full_path
      end
    end
  end
end
