module Imap; end

module Imap::Backup
  class Naming
    INVALID_FILENAME_CHARACTERS = ":%;".freeze
    INVALID_FILENAME_CHARACTER_MATCH = /([#{INVALID_FILENAME_CHARACTERS}])/.freeze

    # `*_path` functions treat `/` as an acceptable character
    def self.to_local_path(name)
      name.gsub(INVALID_FILENAME_CHARACTER_MATCH) do |character|
        hex =
          character.
          codepoints[0].
          to_s(16)
        "%#{hex};"
      end
    end

    def self.from_local_path(name)
      name.gsub(/%(.*?);/) do
        ::Regexp.last_match(1).
          to_i(16).
          chr("UTF-8")
      end
    end
  end
end
