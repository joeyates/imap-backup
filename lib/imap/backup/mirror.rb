require "imap/backup/mirror/map"

module Imap; end

module Imap::Backup
  # Synchronises a folder between a source and destination
  class Mirror
    def initialize(serializer, folder)
      @serializer = serializer
      @folder = folder
    end

    # If necessary, reates the destination folder,
    # then deletes any messages in the destination folder
    # that are not in the local store,
    # sets existing messages' flas
    # then appends any missing messages
    # and saves the mapping file
    # @return [void]
    def run
      ensure_destination_folder
      delete_destination_only_emails
      update_flags
      append_emails
      map.save
    end

    private

    CHUNK_SIZE = 100

    attr_reader :serializer
    attr_reader :folder

    def ensure_destination_folder
      return if folder.exist?

      folder.create
    end

    def delete_destination_only_emails
      uids_to_delete = destination_only_emails
      return if uids_to_delete.empty?

      folder.delete_multi(uids_to_delete)
    end

    def destination_only_emails
      source_uids = serializer.uids
      destination_uids = folder.uids
      destination_uids.filter { |uid| !source_uids.include?(map.source_uid(uid)) }
    end

    def update_flags
      folder.uids.each_slice(CHUNK_SIZE) do |uids|
        update_uids(uids)
      end
    end

    def update_uids(uids)
      uids_and_flags = folder.fetch_multi(uids, ["FLAGS"])
      uids_and_flags.each do |uid_and_flags|
        destination_uid = uid_and_flags[:uid]
        flags = uid_and_flags[:flags]
        source_uid = map.source_uid(destination_uid)
        next if !source_uid

        message = serializer.get(source_uid)
        folder.set_flags([destination_uid], message.flags) if flags.sort != message.flags.sort
      end
    end

    def append_emails
      serializer.each_message do |message|
        existing = map.destination_uid(message.uid)
        next if existing

        # Clients cannot set the 'Recent' flag
        message.flags.reject! { |f| f == :Recent }
        destination_uid = folder.append(message)
        map.map_uids(source: message.uid, destination: destination_uid)
      end
    end

    def map
      @map ||=
        Mirror::Map.new(pathname: map_pathname, destination: destination_email).tap do |map|
          map_ok = map.check_uid_validities(
            source: serializer.uid_validity,
            destination: folder.uid_validity
          )
          if !map_ok
            folder.clear
            map.reset(
              source_uid_validity: serializer.uid_validity,
              destination_uid_validity: folder.uid_validity
            )
          end
        end
    end

    def map_pathname
      "#{serializer.folder_path}.mirror"
    end

    def destination_email
      folder.client.username
    end
  end
end
