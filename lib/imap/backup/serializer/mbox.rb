require "imap/backup/serializer/mbox_store"

module Imap::Backup
  class Serializer::Mbox
    attr_reader :path
    attr_reader :folder

    def initialize(path, folder)
      @path = path
      @folder = folder
    end

    def uids
      store.uids
    end

    def save(uid, message)
      store.add(uid, message)
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
