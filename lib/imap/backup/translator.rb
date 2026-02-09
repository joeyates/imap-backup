require "i18n"
require "locale"

module Imap; end

module Imap::Backup
  # Handles internationalization (i18n) setup and locale detection.
  class Translator
    FALLBACK_LOCALE = :en

    # Initializes i18n with the detected locale.
    # Sets up load paths and configures fallbacks.
    def setup
      I18n.load_path = locale_files
      I18n.backend.load_translations
      I18n.default_locale = FALLBACK_LOCALE
      I18n.locale = detect_locale
    end

    private

    def locale_files
      locales_path = File.expand_path("locales", __dir__)
      Dir.glob(File.join(locales_path, "*.yml"))
    end

    def detect_locale
      # LANG=C should use English
      return FALLBACK_LOCALE if ENV["LANG"] == "C"

      tags = Locale.candidates

      # Find the first locale we have translations for
      tags.each do |tag|
        locale_symbol = tag.language.to_sym
        return locale_symbol if available_locales.include?(locale_symbol)
      end

      FALLBACK_LOCALE
    end

    def available_locales
      locale_files.map do |file|
        File.basename(file, ".yml").to_sym
      end
    end
  end
end
