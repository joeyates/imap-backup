# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [4.0.0.rc2] - 2021-11-18

### Removed

* GMail OAuth2 support. Tokens only last a few days, so this authentication
  method is not usable for automated backups.

## [4.0.0.rc1] - 2021-11-17

### Added

* `local` commands to list accounts, folders and emails and to view single
  emails.
