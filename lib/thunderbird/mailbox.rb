class Thunderbird::Mailbox
  attr_reader :local_folder
  attr_reader :name

  def initialize(local_folder, name)
    @local_folder = local_folder
    @name = name
  end

  def path
    File.join(local_folder.full_path, name)
  end

  def exists?
    File.exists?(path)
  end

  def msf_path
    path + ".msf"
  end

  def msf_exists?
    File.exists?(msf_path)
  end
end
