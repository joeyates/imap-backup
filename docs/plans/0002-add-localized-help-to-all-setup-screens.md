---
title: Add Localized Help to All Setup Screens
description: Add localized help functionality to all setup screens in the menu-driven interface.
---

## Overview

Add localized help functionality to all setup screens in the menu-driven interface, following the pattern established by the Download Strategy Chooser. This will provide users with context-sensitive help text in their preferred language.

## Tasks

- [x] Add `show_help` method to Main Menu ([lib/imap/backup/setup.rb](lib/imap/backup/setup.rb)) and add corresponding translation keys to locale files
- [x] Add `show_help` method to Account Setup Menu ([lib/imap/backup/setup/account.rb](lib/imap/backup/setup/account.rb)) and add corresponding translation keys to locale files
- [x] Add `show_help` method to Global Options Menu ([lib/imap/backup/setup/global_options.rb](lib/imap/backup/setup/global_options.rb)) and add corresponding translation keys to locale files
- [ ] Add `show_help` method to Folder Chooser ([lib/imap/backup/setup/folder_chooser.rb](lib/imap/backup/setup/folder_chooser.rb)) and add corresponding translation keys to locale files

## Principal Files

- [lib/imap/backup/setup.rb](lib/imap/backup/setup.rb) - Main menu
- [lib/imap/backup/setup/account.rb](lib/imap/backup/setup/account.rb) - Account setup menu
- [lib/imap/backup/setup/global_options.rb](lib/imap/backup/setup/global_options.rb) - Global options menu
- [lib/imap/backup/setup/folder_chooser.rb](lib/imap/backup/setup/folder_chooser.rb) - Folder chooser
- [lib/imap/backup/setup/global_options/download_strategy_chooser.rb](lib/imap/backup/setup/global_options/download_strategy_chooser.rb#L52-L56) - Reference implementation
- [lib/imap/backup/locales/en.yml](lib/imap/backup/locales/en.yml) - English translations
- [lib/imap/backup/locales/it.yml](lib/imap/backup/locales/it.yml) - Italian translations

## Acceptance Criteria

- All setup screens have a "help" menu option that displays context-sensitive help text
- Help text is displayed using `I18n.t()` for localization
- Help screens wait for a key press before returning to the menu (following the pattern: `highline.ask I18n.t("...press_key")`)
- All help text exists in both English and Italian locale files
- Implementation follows the pattern established in Download Strategy Chooser
- **Tests**: Every test where i18n is involved must call `Translator.new.setup` to set up the correct locale. If this is missing in tests affected by these tasks, it must be added
