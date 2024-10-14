![Version](https://img.shields.io/gem/v/imap-backup?label=Version&logo=rubygems)
[![Build Status](https://github.com/joeyates/imap-backup/actions/workflows/main.yml/badge.svg)][CI Status]
![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/joeyates/b54fe758bfb405c04bef72dad293d707/raw/coverage.json)
![License](https://img.shields.io/github/license/joeyates/imap-backup?color=brightgreen&label=License)
[![Stars](https://img.shields.io/github/stars/joeyates/imap-backup?style=social)][GitHub Stars]
![Activity](https://img.shields.io/github/last-commit/joeyates/imap-backup/main)

# imap-backup

Backup, restore and migrate email accounts.

# Quick Start

```sh
brew install imap-backup # for macOS
gem install imap-backup --no-document # for Linux
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

See below for a [full list of commands](#commands).

# Installation

<details>
<summary>Docker or Podman</summary>
If you have Docker or Podman installed, the easist way to use imap-backup
is via the container image.

You'll need to choose a path on your computer where your backups will be saved,
we'll use `./my-data` here.

If you have just one account, you can do as follows

```sh
docker run -v ./my-data:/data -ti ghcr.io/joeyates/imap-backup:latest \
  imap-backup single backup \
  --dns 8.8.8.8 \
  --email me@example.com --password mysecret --server imap.example.com \
  --path /data/me_example.com
```

Podman will work exactly the same.

If you have multiple accounts, you can create a configuration file.

You'll need to choose a path on your computer where your configuration will be saved,
we'll use `./my-config` here.

First, run the menu-driven setup program to configure your accounts

```sh
docker run -v ./my-config:/config -v ./my-data:/data -ti ghcr.io/joeyates/imap-backup:latest \
  --dns 8.8.8.8 \
  imap-backup setup -c /config/imap-backup.json
```

Then, run the backup

```sh
docker run -v ./my-config:/config -v ./my-data:/data -ti ghcr.io/joeyates/imap-backup:latest \
  --dns 8.8.8.8 \
  imap-backup backup -c /config/imap-backup.json
```
</details>

<details>
<summary>Homebrew (macOS)</summary>
![Homebrew installs](https://img.shields.io/homebrew/installs/dm/imap-backup?label=Homebrew%20installs)

If you have [Homebrew](https://brew.sh/), do this:

```sh
brew install imap-backup
```
</details>

<details>
<summary>As a Ruby Gem</summary>
* [Rubygem]

```sh
gem install imap-backup --no-document
```

If that doesn't work, see the [detailed installation instructions](/docs/installation/rubygem.md).

[Rubygem]: https://rubygems.org/gems/imap-backup "Ruby gem at rubygems.org"
</details>

<details>
<summary>From Source Code</summary>
If you want to use imap-backup directly from the source code, see [here](/docs/installation/source.md).
</details>

# Setup

Normally you will want to backup a number of email accounts.
Doing so requires the creation of a config file.

You do this via a menu-driven command line program:

Run:

```sh
imap-backup setup
```

As an alternative, if you only want to backup a single account,
you can pass all the necessary parameters directly to the `single backup` command
(see the [`single backup`](/docs/commands/single-backup.md) docs).

## GMail

To use imap-backup with GMail, Office 365 and other services that require
OAuth2 authentication, you can use [email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy).
See [this blog post about using imap-backup with email-oauth2-proxy](https://joeyates.info/posts/back-up-gmail-accounts-with-imap-backup-using-email-oauth2-proxy/).

# Backup

Manually, from the command line:

```sh
imap-backup
```

Alternatively, add it to your crontab.

Backups can also be inspected, for example via [`local show`](/docs/commands/local-show.md)
and exported via [`utils export-to-thunderbird`](/docs/commands/utils-export-to-thunderbird.md).

# Commands

* [`backup`](/docs/commands/backup.md)
* [`local accounts`](/docs/commands/local-accounts.md)
* [`local check`](/docs/commands/local-check.md)
* [`local folders`](/docs/commands/local-folders.md)
* [`local list`](/docs/commands/local-list.md)
* [`local show`](/docs/commands/local-show.md)
* [`migrate`](/docs/commands/migrate.md)
* [`mirror`](/docs/commands/mirror.md)
* [`remote folders`](/docs/commands/remote-folders.md)
* [`restore`](/docs/commands/restore.md)
* [`setup`](/docs/commands/setup.md)
* [`single backup`](/docs/commands/single-backup.md)
* [`utils export-to-thunderbird`](/docs/commands/utils-export-to-thunderbird.md)
* [`utils ignore-history`](/docs/commands/utils-ignore-history.md)

For a full list of available commands, run

```sh
imap-backup help
```

For more information about a command, run

```sh
imap-backup help COMMAND
```

# Performance

There are a couple of performance tweaks that you can use
to improve backup speed.

These are activated via two settings:

* Global setting "Delay download writes",
* Account setting "Multi-fetch size".

See [the performance document](/docs/performance.md) for more information.

# Troubleshooting

If you have problems:

1. ensure that you have the latest release,
2. run `imap-backup` with the `-v` or `--verbose` parameter.

# Development

See the [Developer Documentation].

[Developer Documentation]: https://rubydoc.info/gems/imap-backup "Developer Documentation at Rubydoc.info"
[GitHub Stars]: https://github.com/joeyates/imap-backup/stargazers "GitHub Stars"
[CI Status]: https://github.com/joeyates/imap-backup/actions/workflows/main.yml
