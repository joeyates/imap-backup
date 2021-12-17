require "os"

class Thunderbird
  def data_path
    case
    when OS.windows?
      File.join(ENV["APPDATA"].gsub("\\", "/"), "Thunderbird")
    when OS.linux?
      File.join(Dir.home, ".thunderbird")
    end
  end
end
