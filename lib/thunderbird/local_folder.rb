require "thunderbird/profile"
require "thunderbird/subdirectory"

# A local folder is a file containing emails
class Thunderbird::LocalFolder
  attr_reader :path
  attr_reader :profile

  def initialize(profile, path)
    @profile = profile
    @path = path
  end

  def set_up
    return if path_elements.empty?

    return true if !in_subdirectory?

    subdirectory.set_up
  end

  def full_path
    if in_subdirectory?
      File.join(subdirectory.full_path, folder_name)
    else
      folder_name
    end
  end

  def exists?
    File.exists?(full_path)
  end

  def msf_path
    path + ".msf"
  end

  def msf_exists?
    File.exists?(msf_path)
  end

  private

  def in_subdirectory?
    path_elements.count > 1
  end

  def subdirectory
    if in_subdirectory?
      Thunderbird::Subdirectory.new(profile, subdirectory_path)
    end
  end

  def path_elements
    path.split(File::SEPARATOR)
  end

  def subdirectory_path
    File.join(path_elements[0..-2])
  end

  def folder_name
    path_elements[-1]
  end
end
