# Each subdirectory is "accompanied" by a blank
# file of the same name (without the '.sbd' extension)
class Thunderbird::SubdirectoryPlaceholder
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def exists?
    File.exists?(path)
  end

  def is_regular?
    File.file?(path)
  end

  def touch
    FileUtils.touch path
  end
end
