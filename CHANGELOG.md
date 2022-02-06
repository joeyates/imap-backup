# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [5.0.0] - 2022-02-06

### Added

* A dedicated `migrate` command, distinct from `restore`.

## [4.0.8] - 2021-12-23

### Added

* Experimental: Improved backup speed via multi fetches configurable
  via the Environment variable DOWNLOAD_BLOCK_SIZE.
  The default is still to fetch one message at a time.

### Changed

* Setup menus
  * add titles,
  * indicate when data has been modified,
  * add 'q' shortcut for quick menu exit,
* Debug output to hide passwords printed by the Net::IMAP gem.

## [4.0.4] - 2021-12-21

### Changed

* Configure logger to log synchronously so that output is in sync with
  the Mail gems debugging output.

## [4.0.3] - 2021-12-17

### Added

* Updated `utils export-to-thunderbird` to work on Windows and macOS.

### Removed

* Explicit permissions management on Windows. The config file
  inherits the permissions set on the user's home directory.

## [4.0.2] - 2021-12-13

### Added

* Experimental `utils export-to-thunderbird` command that copies downloaded
  mailboxes to Thunderbird.

## [4.0.1] - 2021-12-05

### Added

* `utils ignore-history` command, useful for when you only want to
  backup future emails.

## [4.0.0.rc2] - 2021-11-18

### Removed

* GMail OAuth2 support. Tokens only last a few days, so this authentication
  method is not usable for automated backups.

## [4.0.0.rc1] - 2021-11-17

### Added

* `local` commands to list accounts, folders and emails and to view single
  emails.
