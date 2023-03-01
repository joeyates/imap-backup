![Version](https://img.shields.io/gem/v/imap-backup?label=Version&logo=rubygems)
[![Build Status](https://github.com/joeyates/imap-backup/actions/workflows/main.yml/badge.svg)][CI Status]
![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/joeyates/b54fe758bfb405c04bef72dad293d707/raw/coverage.json)
![License](https://img.shields.io/github/license/joeyates/imap-backup?color=brightgreen&label=License)

# imap-backup

Backup, restore and migrate email accounts.

# Modes

There are two types of backups:

* Keep all (the default) - progressively saves a local copy of all emails,
* Mirror - adds and deletes emails from the local copy to keep it up to date with the account.

# What You Can Do with a Backup

* Migrate - use the local copy to populate emails on another account. This is a once-only action that deletes any existing emails on the destination account.
* Mirror - make a destination account match the local copy. This action can be repeated.
* Restore - push the local copy back to the original account.

See below for a [full list of commands](#Commands).

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

# Backup

Manually, from the command line:

```sh
imap-backup
```

Alternatively, add it to your crontab.

Backups can also be inspected, for example via [local show](docs/commands/local-show.md)
and exported via [utils export-to-thunderbird](docs/commands/utils-export-to-thunderbird.md).

# Commands

* [backup](docs/commands/backup.md)
* [local accounts](docs/commands/local-accounts.md)
* [local check](docs/commands/local-check.md)
* [local folders](docs/commands/local-folders.md)
* [local list](docs/commands/local-list.md)
* [local show](docs/commands/local-show.md)
* [migrate](docs/commands/migrate.md)
* [mirror](docs/commands/mirror.md)
* [remote folders](docs/commands/remote-folders.md)
* [restore](docs/commands/restore.md)
* [setup](docs/commands/setup.md)
* [utils export-to-thunderbird](docs/commands/utils-export-to-thunderbird.md)
* [utils ignore-history](docs/commands/utils-ignore-history.md)

For a full list of available commands, run

```sh
imap-backup help
```

For more information about a command, run

```sh
imap-backup help COMMAND
```

# Troubleshooting

If you have problems:

1. ensure that you have the latest release,
2. run `imap-backup` with the `-v` or `--verbose` parameter.

# Development

See the [Development documentation](./docs/development.md) for notes
on development and testing.

See [the CHANGELOG](./CHANGELOG.md) to a list of changes that have been
made in each release.

* [Source Code]
* [Code Documentation]
* [Rubygem]
* [CI Status]

[Source Code]: https://github.com/joeyates/imap-backup "Source code at GitHub"
[Code Documentation]: https://rubydoc.info/gems/imap-backup/frames "Code Documentation at Rubydoc.info"
[Rubygem]: https://rubygems.org/gems/imap-backup "Ruby gem at rubygems.org"
[CI Status]: https://github.com/joeyates/imap-backup/actions/workflows/main.yml
