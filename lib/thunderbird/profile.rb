require "thunderbird"

class Thunderbird::Profile
  attr_reader :title
  attr_reader :entries

  # entries are lines from profile.ini
  def initialize(title, entries)
    @title = title
    @entries = entries
  end

  def path
    if relative?
      File.join(Thunderbird.new.data_path, entries[:Path])
    else
      entries[:Path]
    end
  end

  def relative?
    entries[:IsRelative] == "1"
  end
end
