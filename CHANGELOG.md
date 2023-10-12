# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## 14.1.1 - 2023-10-12

### Changed

* Fixed: When handling serialization errors, when using the
  `delayed_metadata` strategy, previously downloaded
  messages are now saved.

## 14.1.0 - 2023-10-12

### Changed

* Messages that cause errors during serialization are now skipped
  end the account backup continues.

## 14.0.0 - 2023-10-11

### Added

* A new `single backup` command that backs up an account
  without the need for a configuration file.

## 13.4.0 - 2023-10-09

### Changed

* Split verbosity into two levels. The first gives local verbose logging,
  the second shows communications with the IMAP server.
* Fixed a bug where under certain conditions `imap-backup version`
  would throw an error.

## 13.3.0 - 2023-10-06

### Changed

* Fixed a bug in mirror mode where new emails were appended to
  the .mbox file, but not to the metadata file.

## 13.2.0 - 2023-10-06

### Changed

* Fixed a bug where the setup connection tester was not actually
  attempting a connection;
* Fixed a bug where unseen messages were being marked as seen on iCloud.

## 13.0.0 - 2023-09-30

### Removed

* Deprecated support of Ruby 2.6.x

## 12.1.0 - 2023-09-25

### Added

* An `--automatic-namespaces` option to automatically select
  source and destination prefixes and delimiters for
  the `migrate` and `mirror` commands.

## 12.0.0 - 2023-09-16

### Changed

* Fixed a bug in serialization where message lengths were calculated
  in Unicode codepoints, not in bytes;
* Delayed login of the IMAP client, speeding up operations where the
  client login was not actually necessary.

## 11.1.0 - 2023-08-31

### Changed

* Changed handling of messages with encoding errors in the
  body and the From header.

## 11.0.1 - 2023-08-01

### Changed

* Fixed error handling behaviour in transactions. Closes #164

## 11.0.0 - 2023-07-25

### Changed

* Default downloading strategy now delays writing metadata until
  the whole folder has been downloaded. For very large mailboxes
  (e.g. with >100k messages) this results in an approximately
  30x speedup in download times. The strategy can be chosen in the setup
  program, under 'global options';
* When any account backup fails, the program now exits with a non-zero
  exit code.

## 10.0.0 - 2023-07-16

* Improved logging output for Thunderbird exports,
* Stopped exports when the destination profile is not yet ready.

## 9.3.2 - 2023-06-04

## Changed

* Improved performance of large backups by avoiding unnecessary serialized
  IMAP data migration and validation checks.

## 9.3.1 - 2023-05-12

## Changed

* Previously, when help was requested on a subcommand method,
  the output was of listing all subcommand methods.
  Now, the output is now the help for that specific method.

## 9.2.0 - 2023-03-01

## Changed

* Handle invalid file name characters (specifically ':')
  in folder names. Invalid names are encoded to hex codes.
  As the encoding uses '%' and ';' to delimit encoded hex values,
  theses characters themselves are now considered 'invalid' for
  serialized folder names and are encoded.

## 9.1.1 - 2023-02-19

### Changed

* BUGFIX: Correctly accept logging options when running `migrate` and
  `mirror` commands.

## 9.1.0 - 2023-02-18

### Changed

* When a single account throws an error, capture log it and
  keep running, so other accounts get backed up.

## 9.0.2 - 2023-01-09

### Changed

* BUGFIX: When an account has `folder_blacklist` set but no list of
  configured folders, it now backs up all folders.

## 9.0.1 - 2022-12-29

### Changed

* Made `--reset` option on `migrate` optional. Now, existing emails
  in destination folders are kept.

## 9.0.0 - 2022-12-29

### Added

* Options for setting source and destination delimiters for the `migrate` and `mirror` commands.

## 8.0.1 - 2022-09-24

### Changed

* Filtered out non-standard flags from `migrate` and `restore`.

## 8.0.0 - 2022-09-24

### Added

* An account option 'folder_blacklist'. When set the user chooses
  which folders to **exclude** from backups. Otherwise, the folders
  chosen by the user are the ones to **include**,
* Provision of JSON output for the 'remote folders' command,
* A 'remote namespaces' command to help with configuration of
  the 'migrate' and 'mirror' commands.

### Changed

* Removed 'Experimental' warning from 'migrate' command,
* Removed 'Experimental' warning from 'export-to-thunderbird' command,
* Renamed Folder#*_flags methods,
* Improved setup account menu ordering,
* An account's connection_options can now be cleared by entering an empty string.

### Removed

* Deprecated `folders` command, replaced by `remote folders`.

## [8.0.0.rc1] - 2022-09-19

### Added

* --config parameter to allow for non-default placing of the configuration file

### Removed

* Deprecated `status` command, replaced by `stats`.

## [7.0.2] - 2022-09-17

* Changed logging behaviour:
  * Made info the normal logger level,
  * Removed configuration 'debug' setting,
  * Added a --verbose flag,
  * Add a --quiet flag.
* Corrected handling of account connection options after changes.

## [7.0.1] - 2022-09-16

* Added a 'mirror mode' to account configuration that changes backup behaviour:
  * removes local folders that are no longer to be backed up,
  * removes emails that are no longer present on the server,
  * updates flags on the local backup to match those on the server.
* Added a 'mirror' command that takes a 'mirror mode' backup and copies
  it to another server.
* Added a '--refresh' option to the backup command that, updates flags
  on the local backup to match those on the server, even for accounts
  that are *not* in 'mirror mode'.

## [7.0.0.rc1] - 2022-08-30

## Changed

* Added backup and restore of IMAP flags (e.g. "Seen", "Draft").
* Introduced a new metadata format.
* Included data about message offsets and lengths in the new metadata to
  facilitate for future integrity checks.
* Added a migrator to transform the old (version 2) metadata files
  into the newer (version 3) files.

## [6.2.1] - 2022-07-12

## Changed

* Added handling for folder names supplied by the IMAP server
  with badly encoded names (e.g. UTF-8 instead of UTF-7)

## [6.2.0] - 2022-07-12

## Changed

* Improved the speed of some operations by tracking mailbox selection
  to avoid repeated calls to select the same mailbox.
* Added handling of append errors during migration.

## [6.1.0] - 2022-07-11

## Changed

* Added a workaround option for providers that set the '\Seen' flag when
  emails are fetched.

## [6.0.1] - 2022-06-09

## Changed

* Memoized connections to reduce unnecessary reconnections and the risk
  of exceeding server connection limits.

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
