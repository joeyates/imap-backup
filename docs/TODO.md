# Add Internationalization (i18n) Support

Status: [ ]

## Description

Add internationalization support to make imap-backup accessible to non-English-speaking users. The primary focus should be on the menu-driven setup interface, which contains the most user-facing text. This will allow the application to display messages and prompts in the user's preferred language based on locale environment variables (LANGUAGE, LANG, LC_*).

## Technical Specifics

- Use the `locale` and `i18n` gems
- Override the `locale` gem's behaviour when LANG=C (use `:en`)
- Store translations under `lib/imap/backup/locales`
- Prioritize translating the menu-driven setup interface (`lib/imap/backup/setup.rb` and related files)
- Extract all user-facing strings into translation files with locale "en"
- Add Italian translations
