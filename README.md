![Version](https://img.shields.io/gem/v/imap-backup?label=Version&logo=rubygems)
[![Build Status](https://github.com/joeyates/imap-backup/actions/workflows/main.yml/badge.svg)][CI Status]
![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/joeyates/b54fe758bfb405c04bef72dad293d707/raw/coverage.json)
![License](https://img.shields.io/github/license/joeyates/imap-backup?color=brightgreen&label=License)

# imap-backup

Backup, restore and migrate email accounts.

The backups can then be restored, used to migrate to another service,
inspected or exported.

  * [Source Code]
  * [Code Documentation]
  * [Rubygem]
  * [CI Status]

[Source Code]: https://github.com/joeyates/imap-backup "Source code at GitHub"
[Code Documentation]: https://rubydoc.info/gems/imap-backup/frames "Code Documentation at Rubydoc.info"
[Rubygem]: https://rubygems.org/gems/imap-backup "Ruby gem at rubygems.org"
[CI Status]: https://github.com/joeyates/imap-backup/actions/workflows/main.yml

# Backup Emails

imap-backup downloads emails and stores them on disk.

The backup is incremental and interruptable, so backups won't get messed if your connection goes down during an operation.

# Installation

## Homebrew (macOS)

If you have [Homebrew](https://brew.sh/), do this:

```sh
brew install imap-backup
```

## As a Ruby Gem

```sh
gem install imap-backup
```

If that doesn't work, see the [detailed installation instructions](docs/installation/rubygem.md).

## From Source Code

If you want to use imap-backup directly from the source code, see [here](docs/installation/source.md).

# Setup

As a first step, you need to add accounts via a menu-driven command
line program:

Run:

```sh
imap-backup setup
```

## GMail

To use imap-backup with GMail, you will need to enable 'App passwords' on your account.

# Run Backup

Manually, from the command line:

```sh
imap-backup
```

Alternatively, add it to your crontab.

Emails are stored on disk in [Mbox files](./docs/files/mboxrd.md) for each folder, with metadata
stored in [Imap files](./docs/files/imap.md).

# Commands

* [folders](./commands/folders.md)
* [restore](./commands/restore.md)
* [status](./commands/status.md)

For a full list of available commands, run

```sh
imap-backup help
```

For more information about a command, run

```sh
imap-backup help COMMAND
```

## Configuration

`imap-backup setup` creates the file `~/.imap-backup/config.json`.

[More information about configuration is available in the specific documentation](./docs/configuration.md).

# Troubleshooting

If you have problems:

1. ensure that you have the latest release,
2. turn on debugging output via the `imap-backup setup` main menu.

# Development

See the [Development documentation](./docs/development.md)
