module Imap::Backup
  class Naming
    INVALID_FILENAME_CHARACTERS = %w(: % ;).freeze
    INVALID_FILENAME_CHARACTER_MATCH = %r[(#{INVALID_FILENAME_CHARACTERS})]

    # `*_path` functions treat `/` as an acceptable character
    def self.to_local_path(name)
      name.gsub(INVALID_FILENAME_CHARACTER_MATCH) do |character|
        "%" +
          character.
          codepoints[0].
          to_s(16) +
          ";"
      end
    end
   
    def self.from_local_path(name)
      name.gsub(/%(.*?);/) do
        $1.to_i(16).chr("UTF-8")
      end
    end
  end
end
