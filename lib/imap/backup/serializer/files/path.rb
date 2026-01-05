module Imap; end

module Imap::Backup
  class Serializer; end
  class Serializer::Files; end

  # A Data class representing the path to a folder's serialized data
  # it contains two elements: the base path and the folder name.
  # The base path is the root path for an account's backup,
  # and the folder name is the name of the folder within that account.
  Serializer::Files::Path = Data.define(:base_path, :folder_name) do
    # @return [String] the full path to the folder's serialized data
    def to_s
      File.join(base_path, folder_name)
    end
  end
end
