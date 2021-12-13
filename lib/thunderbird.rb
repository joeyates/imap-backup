class Thunderbird
  def data_path
    # TODO: Handle other OSes
    File.join(Dir.home, ".thunderbird")
  end
end
