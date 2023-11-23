require "json"

module Imap; end

module Imap::Backup
  class Mirror; end

  # Keeps track of the mapping between source and destination UIDs
  class Mirror::Map
    def initialize(pathname:, destination:)
      @pathname = pathname
      @destination = destination
      @store = nil
      @destination_store = nil
      @source_uid_validity = nil
      @destination_uid_validity = nil
      @map = nil
    end

    # @return [Boolean] whether the supplied values match the existing
    #  UID validity values
    def check_uid_validities(source:, destination:)
      store
      return false if source != source_uid_validity
      return false if destination != destination_uid_validity

      true
    end

    # Sets, or resets to an empty state
    # @return [void]
    def reset(source_uid_validity:, destination_uid_validity:)
      destination_store["source_uid_validity"] = source_uid_validity
      @source_uid_validity = nil
      destination_store["destination_uid_validity"] = destination_uid_validity
      @destination_uid_validity = nil
      destination_store["map"] = {}
      @map = nil
    end

    # @param destination_uid [Integer] a message UID from the destination server
    #
    # @return [Integer, nil] the source UID that is equivalent to the given destination UID
    #   or nil if it is not found
    def source_uid(destination_uid)
      if destination_store == {}
        raise "Assign UID validities with #reset before calling #source_uid"
      end

      map.key(destination_uid)
    end

    # @param source_uid [Integer] a message UID from the source server
    #
    # @return [Integer, nil] the destination UID that is equivalent to the given source UID
    #   or nil if it is not found
    def destination_uid(source_uid)
      if destination_store == {}
        raise "Assign UID validities with #reset before calling #destination_uid"
      end

      map[source_uid]
    end

    # Creates a mapping between message UIDs on the source
    # and destination servers
    # @return [void]
    def map_uids(source:, destination:)
      raise "Assign UID validities with #reset before calling #map_uids" if destination_store == {}

      map[source] = destination
    end

    # Saves the map to disk as JSON
    # @return [void]
    def save
      File.write(pathname, store.to_json)
    end

    private

    attr_reader :pathname
    attr_reader :destination

    def store
      @store ||=
        if File.exist?(pathname)
          content = File.read(pathname)
          store = JSON.parse(content)
          if store[destination]
            destination_store = store[destination]
            map = destination_store["map"]
            map.transform_keys!(&:to_i)
          end
          store
        else
          {}
        end
    end

    def destination_store
      @destination_store ||= store[destination] ||= {}
    end

    def source_uid_validity
      @source_uid_validity ||= destination_store["source_uid_validity"]
    end

    def destination_uid_validity
      @destination_uid_validity ||= destination_store["destination_uid_validity"]
    end

    def map
      @map ||= destination_store["map"]
    end
  end
end
