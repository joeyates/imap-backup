module Imap::Backup
  class Mirror; end

  class Mirror::Map
    attr_reader :pathname
    attr_reader :destination

    def initialize(pathname:, destination:)
      @pathname = pathname
      @destination = destination
      @store = nil
      @destination_store = nil
      @source_uid_validity = nil
      @destination_uid_validity = nil
      @map = nil
    end

    def check_uid_validities(source:, destination:)
      store
      return false if source != source_uid_validity
      return false if destination != destination_uid_validity

      true
    end

    def reset(source_uid_validity:, destination_uid_validity:)
      destination_store["source_uid_validity"] = source_uid_validity
      @source_uid_validity = nil
      destination_store["destination_uid_validity"] = destination_uid_validity
      @destination_uid_validity = nil
      destination_store["map"] = {}
      @map = nil
    end

    def source_uid(destination_uid)
      if destination_store == {}
        raise "Assign UID validities with #reset before calling #source_uid"
      end

      map.key(destination_uid)
    end

    def destination_uid(source_uid)
      if destination_store == {}
        raise "Assign UID validities with #reset before calling #destination_uid"
      end

      map[source_uid]
    end

    def map_uids(source:, destination:)
      raise "Assign UID validities with #reset before calling #map_uids" if destination_store == {}

      map[source] = destination
    end

    def save
      File.write(pathname, store.to_json)
    end

    private

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
