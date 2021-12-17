require "thunderbird"
require "thunderbird/profile"

# http://kb.mozillazine.org/Profiles.ini_file
class Thunderbird::Profiles
  def default
    title, entries = blocks.find { |_name, entries| entries[:Default] == "1" }

    Thunderbird::Profile.new(title, entries) if title
  end

  def profile(name)
    title, entries = blocks.find { |_name, entries| entries[:Name] == name }

    Thunderbird::Profile.new(title, entries) if title
  end

  private

  # Parse profiles.ini.
  # Blocks start with a title, e.g. '[Abc]'
  # and are followed by a number of lines
  def blocks
    @blocks ||= begin
      blocks = {}
      File.open(profiles_ini_path, "rb") do |f|
        title = nil
        entries = nil

        loop do
          line = f.gets
          if !line
            blocks[title] = entries if title
            break
          end

          line.chomp!

          # Is this line the start of a new block
          match = line.match(/\A\[([A-Za-z0-9]+)\]\z/)
          if match
            # Store what we got before this title as a new block
            blocks[title] = entries if title

            # Start a new block
            title = match[1]
            entries = {}
          else
            # Collect entries until we get to the next title
            if line != ""
              key, value = line.split("=")
              entries[key.to_sym] = value
            end
          end
        end
      end

      blocks
    end
  end

  def profiles_ini_path
    File.join(Thunderbird.new.data_path, "profiles.ini")
  end
end
