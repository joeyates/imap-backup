![Version](https://img.shields.io/gem/v/imap-backup?label=Version&logo=rubygems)
[![Build Status](https://github.com/joeyates/imap-backup/actions/workflows/main.yml/badge.svg)][CI Status]
![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/joeyates/b54fe758bfb405c04bef72dad293d707/raw/coverage.json)
![License](https://img.shields.io/github/license/joeyates/imap-backup?color=brightgreen&label=License)
[![Stars](https://img.shields.io/github/stars/joeyates/imap-backup?style=social)][GitHub Stars]

# imap-backup

Backup, restore and migrate email accounts.

# Quick Start

```sh
brew install imap-backup # for macOS
gem install imap-backup # for Linux
imap-backup setup
imap-backup
```

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

![Homebrew installs](https://img.shields.io/homebrew/installs/dm/imap-backup?label=Homebrew%20installs)

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

To use imap-backup with GMail, Office 365 and other services that require
OAuth2 authentication, you can use [email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy)
to handle authentication, and then connect to the proxy on a local port.

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

# Performace

There are a couple of performance tweaks that you can use
to improve backup speed.

These are activated via two settings:

* Global setting "Delay download writes"
* Account setting "Multi-fetch size"

As with all performance tweaks, there are trade-offs.
If you are using a small virtual server or Raspberry Pi
to run your backups, you will probably want to leave
the default settings.
If, on the other hand, you are using a computer with a
fair bit of RAM, and you are dealing with a *lot* of email,
then changing these settings may be worthwhile.

## Delay download writes

This setting affects all account backups.

By default, `imap-backup` uses the "delay metadata" strategy.
As messages are being backed-up, the message *text*
is written to disk, while the related metadata is stored in memory.

While this uses a little more memory, it avoids rewiting a growing JSON
file for every message, speeding things up and reducing disk wear.

The alternative strategy, called "direct", writes everything to disk
as it is received. This method is slower, but has the advantage
of using slightly less memory, which may be important on very
resource-limited systems, like Raspberry Pis.

## Multi-fetch Size

By default, during backup, each message is downloaded one-by-one.

Using this setting, you can download chunks of emails at a time,
potentially speeding up the process.

Using multi-fetch *will* mean that the backup process will use
more memory - equivalent to the size of the groups of messages
that are downloaded.

This behaviour may also exceed the rate limits on your email provider,
so it's best to check before cranking it up!

# Troubleshooting

If you have problems:

1. ensure that you have the latest release,
2. run `imap-backup` with the `-v` or `--verbose` parameter.

# Development

![Activity](https://img.shields.io/github/last-commit/joeyates/imap-backup/main)

See the [Development documentation](./docs/development.md) for notes
on development and testing.

See [the CHANGELOG](./CHANGELOG.md) to a list of changes that have been
made in each release.

* [Source Code]
* [Code Documentation]
* [Rubygem]
* [CI Status]

[Source Code]: https://github.com/joeyates/imap-backup "Source code at GitHub"
[GitHub Stars]: https://github.com/joeyates/imap-backup/stargazers "GitHub Stars"
[Code Documentation]: https://rubydoc.info/gems/imap-backup/frames "Code Documentation at Rubydoc.info"
[Rubygem]: https://rubygems.org/gems/imap-backup "Ruby gem at rubygems.org"
[CI Status]: https://github.com/joeyates/imap-backup/actions/workflows/main.yml
