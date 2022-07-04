# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [6.0.0] - 2022-06-04

## Changed

* Deprecated the 'status' command, in favour of the new 'stats' command.
* Added new 'stats' command, with optional JSON output.
* Resolved long running CI problem with feature specs failing due to
  too many active IMAP connections.

## [6.0.0.rc2] - 2022-04-03

## Changed

* Substituted the use of the Environment variable DOWNLOAD_BLOCK_SIZE
  with an account-level setting: `multi_fetch_size`.

## [6.0.0.rc1] - 2022-02-25

## Changed

* Refactored serialization code to simplify successive
  modifications to metadata serialization.

## [5.2.0] - 2022-02-24

## Changed

* During backup and/or restore, when there is a clash in a
  folder's uid_validity between the local copy and the server's
  copy, the local folder is now renamed using '-' as a
  separator (previously it was '.'). This should reduce
  compatibility problems with certain IMAP servers.

## [5.1.0] - 2022-02-12

## Changed

* The restore command now takes a single argument:
  the email to restore. The previous (deprecated) invocation
  which restores all accounts by default, or those indicated
  by the --accounts parameter, is still supported.

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
