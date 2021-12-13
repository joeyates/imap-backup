require "thunderbird/profile"
require "thunderbird/local_folder_placeholder"

class Thunderbird::LocalFolder
  attr_reader :folder_path
  attr_reader :profile

  def initialize(profile, folder_path)
    @profile = profile
    @folder_path = folder_path
  end

  def local_folder_placeholder
    if parent
      path = File.join(parent.full_path, folder_path_elements[-1])
      Thunderbird::LocalFolderPlaceholder.new(path)
    end
  end

  def directory_is_directory?
    File.directory?(full_path)
  end

  def full_path
    File.join(profile.local_folders_path, relative_path)
  end

  def parent
    if folder_path_elements.count > 0
      self.class.new(profile, File.join(folder_path_elements[0..-2]))
    end
  end

  def folder_path_elements
    folder_path.split(File::SEPARATOR)
  end

  def directory_exists?
    File.exists?(full_path)
  end

  def is_directory?
    File.directory?(full_path)
  end

  def subdirectories
    folder_path_elements.map { |p| "#{p}.sbd" }
  end

  def relative_path
    File.join(subdirectories)
  end

  def set_up
    ok = check
    return if !ok

    ensure_initialized
  end

  def ensure_initialized
    return true if !parent

    parent.ensure_initialized

    local_folder_placeholder.ensure_initialized

    FileUtils.mkdir_p full_path
  end

  def check
    return true if !parent

    parent_ok = parent.check

    return if !parent_ok

    case
    when local_folder_placeholder.exists? && !directory_exists?
      Kernel.puts "Can't set up folder '#{folder_path}': '#{local_folder_placeholder.path}' exists, but '#{full_path}' is missing"
      false
    when directory_exists? && !local_folder_placeholder.exists?
      Kernel.puts "Can't set up folder '#{folder_path}': '#{full_path}' exists, but '#{local_folder_placeholder.path}' is missing"
      false
    when local_folder_placeholder.exists? && !local_folder_placeholder.is_regular?
      Kernel.puts "Can't set up folder '#{folder_path}': '#{local_folder_placeholder.path}' exists, but it is not a regular file"
      false
    when directory_exists? && !is_directory?
      Kernel.puts "Can't set up folder '#{folder_path}': '#{full_path}' exists, but it is not a directory"
      false
    else
      true
    end
  end
end
