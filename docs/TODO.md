# Add Internationalization (i18n) Support

Status: [x]

## Description

Add internationalization support to make imap-backup accessible to non-English-speaking users. The primary focus should be on the menu-driven setup interface, which contains the most user-facing text. This will allow the application to display messages and prompts in the user's preferred language based on locale environment variables (LANGUAGE, LANG, LC_*).

## Technical Specifics

- Use the `locale` and `i18n` gems
- Override the `locale` gem's behaviour when LANG=C (use `:en`)
- Store translations under `lib/imap/backup/locales`
- Prioritize translating the menu-driven setup interface (`lib/imap/backup/setup.rb` and related files)
- Extract all user-facing strings into translation files with locale "en"
- Add Italian translations

# Add Localized Help to All Setup Screens

Status: [x]

## Description

Currently, only the Download Strategy Chooser screen has localized help functionality (via the `show_help` method). This TODO involves adding similar localized help to all other setup screens in the menu-driven interface to provide users with context-sensitive assistance in their preferred language.

## Technical Specifics

- The Download Strategy Chooser at [lib/imap/backup/setup/global_options/download_strategy_chooser.rb](lib/imap/backup/setup/global_options/download_strategy_chooser.rb#L52-L56) already implements localized help as a reference implementation
- Screens that need localized help added:
  - Main menu ([lib/imap/backup/setup.rb](lib/imap/backup/setup.rb))
  - Account setup menu ([lib/imap/backup/setup/account.rb](lib/imap/backup/setup/account.rb))
  - Global options menu ([lib/imap/backup/setup/global_options.rb](lib/imap/backup/setup/global_options.rb))
  - Other setup screens (folder chooser, backup path, etc.)
- Add translation keys for help text to locale files (`lib/imap/backup/locales/en.yml` and `lib/imap/backup/locales/it.yml`)
- Follow the pattern: menu choice for "help" that displays localized help text and waits for key press

# Fix mboxrd Quote Serialization Bug

Status: [ ]

## Description

The `add_extra_quote` method in `Email::Mboxrd::Message` incorrectly quotes all lines beginning with `From` (e.g. `From:` headers), rather than only lines beginning with `From ` (with a trailing space). The corresponding `clean_serialized` method has the same problem on load. This results in mbox files storing corrupted content. The fix involves correcting both regexes, bumping the metadata format version, and migrating existing files on load.

## Technical Specifics

- In [lib/imap/backup/serializer/imap.rb](lib/imap/backup/serializer/imap.rb):
  - Bump `CURRENT_VERSION` from `3` to `3.1`
  - Add `3` to `LOADABLE_VERSIONS`: `LOADABLE_VERSIONS = [3, 3.1].freeze`
  - In `ensure_loaded`, use a `case data[:version]` branch:
    - `when CURRENT_VERSION` — load messages normally
    - `when 3` — load each message using the old (buggy) deserialization logic (`from_serialized_v3`), and set `@version = CURRENT_VERSION` so the next save writes version 3.1
- In [lib/imap/backup/email/mboxrd/message.rb](lib/imap/backup/email/mboxrd/message.rb):
  - Fix `add_extra_quote`: change regex from `/\n(>*From)/` to `/\n(>*From )/`
  - Fix `clean_serialized`: change regex from `/^>(>*From)/` to `/^>(>*From )/`
  - Add `clean_serialized_v3` (using the old regex `/^>(>*From)/`) and a corresponding `from_serialized_v3` class method for use during migration of version 3 files
