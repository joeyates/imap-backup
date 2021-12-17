require "thunderbird/profiles"

class Thunderbird::Install
  attr_reader :title
  attr_reader :entries

  # entries are lines from profile.ini
  def initialize(title, entries)
    @title = title
    @entries = entries
  end

  def default
    Thunderbird::Profiles.new.profile_for_path(entries[:Default])
  end
end
