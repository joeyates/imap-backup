module Imap; end

module Imap::Backup
  class Serializer; end
  class Serializer::Files; end

  # A Data class representing the path to a folder's serialized data
  # it contains two elements: the base path and the folder name.
  # The base path is the root path for an account's backup,
  # and the folder name is the name of the folder within that account.
  # If the folder name is nil, the path represents the base path only.
  Serializer::Files::Path = Data.define(:base_path, :folder_name) do
    # @return [String] the full path to the folder's serialized data
    def to_s
      File.join(base_path, folder_name)
    end

    # @return [String] the directory containing the folder's serialized data
    def directory
      if folder_name
        File.dirname(to_s)
      else
        base_path
      end
    end
  end
end
