require "imap/backup/serializer/mbox_store"

module Imap::Backup
  class Serializer::Mbox
    attr_reader :path
    attr_reader :folder

    def initialize(path, folder)
      @path = path
      @folder = folder
    end

    def apply_uid_validity(value)
      case
      when store.uid_validity.nil?
        store.uid_validity = value
        nil
      when store.uid_validity == value
        # NOOP
        nil
      else
        apply_new_uid_validity value
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

    def apply_new_uid_validity(value)
      digit = 0
      new_name = nil
      loop do
        extra = digit.zero? ? "" : ".#{digit}"
        new_name = "#{folder}.#{store.uid_validity}#{extra}"
        test_store = Serializer::MboxStore.new(path, new_name)
        break if !test_store.exist?

        digit += 1
      end
      rename_store new_name, value
    end

    def rename_store(new_name, value)
      store.rename new_name
      @store = nil
      store.uid_validity = value
      new_name
    end

    def relative_path
      File.dirname(folder)
    end

    def containing_directory
      File.join(path, relative_path)
    end

    def full_path
      File.expand_path(containing_directory)
    end

    def create_containing_directory
      if !File.directory?(full_path)
        Utils.make_folder(
          path, relative_path, Serializer::DIRECTORY_PERMISSIONS
        )
      end

      if Utils.mode(full_path) !=
         Serializer::DIRECTORY_PERMISSIONS
        FileUtils.chmod Serializer::DIRECTORY_PERMISSIONS, full_path
      end
    end
  end
end
