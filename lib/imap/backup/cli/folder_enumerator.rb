module Imap::Backup
  class CLI::FolderEnumerator
    attr_reader :destination
    attr_reader :destination_delimiter
    attr_reader :destination_prefix
    attr_reader :source
    attr_reader :source_delimiter
    attr_reader :source_prefix

    def initialize(
      destination:,
      source:,
      destination_delimiter: "/",
      destination_prefix: "",
      source_delimiter: "/",
      source_prefix: ""
    )
      @destination = destination
      @destination_delimiter = destination_delimiter
      @destination_prefix = destination_prefix
      @source = source
      @source_delimiter = source_delimiter
      @source_prefix = source_prefix
    end

    def each
      return enum_for(:each) if !block_given?

      glob = File.join(source_local_path, "**", "*.imap")
      Pathname.glob(glob) do |path|
        name = source_folder_name(path)
        serializer = Serializer.new(source_local_path, name)
        folder = destination_folder_for(name)
        yield serializer, folder
      end
    end

    private

    def destination_folder_for(name)
      parts = name.split(source_delimiter)
      no_source_prefix =
        if source_prefix != "" && parts.first == source_prefix
          parts[1..-1]
        else
          parts
        end

      with_destination_prefix =
        if destination_prefix && destination_prefix != ""
          no_source_prefix.unshift(destination_prefix)
        else
          no_source_prefix
        end

      destination_name = with_destination_prefix.join(destination_delimiter)

      Account::Folder.new(
        destination.connection,
        destination_name
      )
    end

    def source_local_path
      source.local_path
    end

    def source_folder_name(imap_pathname)
      base = Pathname.new(source_local_path)
      imap_name = imap_pathname.relative_path_from(base).to_s
      dir = File.dirname(imap_name)
      stripped = File.basename(imap_name, ".imap")
      if dir == "."
        stripped
      else
        File.join(dir, stripped)
      end
    end
  end
end
