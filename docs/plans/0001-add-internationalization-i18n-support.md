---
title: Add Internationalization (i18n) Support
description: Add internationalization support to make imap-backup accessible to non-English-speaking users.
---

## Overview

Add internationalization support to imap-backup using the `i18n` and `locale` gems, focusing primarily on the menu-driven setup interface. The implementation will detect the user's locale from environment variables (LANGUAGE, LANG, LC_*) and display messages in their preferred language, with English as the default and Italian as the first additional translation.

## Tasks

- [x] Add `i18n` and `locale` gems to runtime dependencies
- [x] Create locale infrastructure with directory structure at [lib/imap/backup/locales](lib/imap/backup/locales)
- [x] Implement locale detection using the `locale` gem with override for LANG=C → :en
- [x] Extract and translate strings from [lib/imap/backup/setup.rb](lib/imap/backup/setup.rb) main menu
- [x] Extract and translate strings from [lib/imap/backup/setup/account.rb](lib/imap/backup/setup/account.rb) and [lib/imap/backup/setup/account/header.rb](lib/imap/backup/setup/account/header.rb)
- [x] Extract and translate strings from [lib/imap/backup/setup/global_options.rb](lib/imap/backup/setup/global_options.rb) and [lib/imap/backup/setup/global_options/download_strategy_chooser.rb](lib/imap/backup/setup/global_options/download_strategy_chooser.rb)
- [x] Extract and translate strings from [lib/imap/backup/setup/asker.rb](lib/imap/backup/setup/asker.rb)
- [x] Extract and translate strings from [lib/imap/backup/setup/folder_chooser.rb](lib/imap/backup/setup/folder_chooser.rb)
- [x] Extract and translate strings from [lib/imap/backup/setup/backup_path.rb](lib/imap/backup/setup/backup_path.rb)
- [x] Update CLI error messages and user-facing outputs outside setup
- [ ] Create Italian (it.yml) locale file with translations
- [ ] Create [docs/i18n.md](docs/i18n.md) documenting i18n usage and contribution guidelines for translators
- [ ] Add an (undated, unversioned) entry to [Changelog.md](Changelog.md) describing the changes

## Principal Files

### Core Setup Files
- [lib/imap/backup/setup.rb](lib/imap/backup/setup.rb) - Main menu
- [lib/imap/backup/setup/account.rb](lib/imap/backup/setup/account.rb) - Account modification menu
- [lib/imap/backup/setup/account/header.rb](lib/imap/backup/setup/account/header.rb) - Account header display
- [lib/imap/backup/setup/asker.rb](lib/imap/backup/setup/asker.rb) - Interactive prompts
- [lib/imap/backup/setup/helpers.rb](lib/imap/backup/setup/helpers.rb) - Helper methods
- [lib/imap/backup/setup/backup_path.rb](lib/imap/backup/setup/backup_path.rb) - Backup path selection
- [lib/imap/backup/setup/folder_chooser.rb](lib/imap/backup/setup/folder_chooser.rb) - Folder selection
- [lib/imap/backup/setup/global_options.rb](lib/imap/backup/setup/global_options.rb) - Global options menu
- [lib/imap/backup/setup/global_options/download_strategy_chooser.rb](lib/imap/backup/setup/global_options/download_strategy_chooser.rb) - Download strategy menu

### New Files
- [lib/imap/backup/locales/en.yml](lib/imap/backup/locales/en.yml) - English translations
- [lib/imap/backup/locales/it.yml](lib/imap/backup/locales/it.yml) - Italian translations
- [docs/i18n.md](docs/i18n.md) - Internationalization documentation

### Configuration Files
- [imap-backup.gemspec](imap-backup.gemspec) - Add gem dependencies

## Acceptance Criteria

- The `i18n` and `locale` gems are added to runtime dependencies in [imap-backup.gemspec](imap-backup.gemspec)
- Locale files are stored in [lib/imap/backup/locales](lib/imap/backup/locales) directory
- Locale detection works correctly using the `locale` gem, reading LANGUAGE, LANG, and LC_* environment variables
- LANG=C is properly overridden to use English locale (:en)
- All user-facing strings in the setup menu system are extracted to translation files
- English locale file (en.yml) contains all translated strings with proper keys
- Italian locale file (it.yml) provides complete translations
- Running `imap-backup setup` displays menus in the user's locale
- Tests verify locale detection and string translation functionality
- All existing tests continue to pass
- [docs/i18n.md](docs/i18n.md) explains how to add new translations and contribute to internationalization
