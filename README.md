[![Build Status](https://github.com/joeyates/imap-backup/actions/workflows/main.yml/badge.svg)][CI Status]
![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/joeyates/b54fe758bfb405c04bef72dad293d707/raw/coverage.json)
![License](https://img.shields.io/github/license/joeyates/imap-backup?color=brightgreen)

# imap-backup

*Backup GMail (or other IMAP) accounts to disk*

  * [Source Code]
  * [API documentation]
  * [Rubygem]
  * [CI Status]

[Source Code]: https://github.com/joeyates/imap-backup "Source code at GitHub"
[API documentation]: https://rubydoc.info/gems/imap-backup/frames "RDoc API Documentation at Rubydoc.info"
[Rubygem]: https://rubygems.org/gems/imap-backup "Ruby gem at rubygems.org"
[CI Status]: https://github.com/joeyates/imap-backup/actions/workflows/main.yml

# Installation

```shell
$ gem install 'imap-backup'
```

# Commands

For a full list, run

```
$ imap-backup help
```

For more information about a command, run

```shell
$ imap-backup help COMMAND
```

# Setup

In order to do backups, you need to add accounts via a menu-driven command
line program:

Run:

```shell
$ imap-backup setup
```

## GMail

To use imap-backup with GMail, you will need to enable 'App passwords' on your account.

## Folders

By default, all folders are backed-up. You can override this by choosing
specific folders.

## Configuration file

`setup` creates the file `~/.imap-backup/config.json`

E.g.:

```json
{
  "accounts": [
    {
      "username": "my.user@gmail.com",
      "password": "secret",
      "local_path": "/path/to/backup/root",
      "folders":
        [
          {"name": "[Gmail]/All Mail"},
          {"name": "my_folder"}
        ]
    }
  ]
}
```

It connects to GMail by default, but you can also specify a server:

```json
{
  "accounts": [
    {
      "username": "my.user@gmail.com",
      "password": "secret",
      "server": "my.imap.example.com",
      "local_path": "/path/to/backup/root",
      "folders":
        [
          {"name": "[Gmail]/All Mail"},
          {"name": "my_folder"}
        ]
    }
  ]
}
```

## Connection options

You can override the parameters passed to `Net::IMAP` with `connection_options`.

Specifically, if you are using a self-signed certificate and get SSL errors, e.g.
`certificate verify failed`, you can choose to not verify the TLS connection:

```json
{
  "accounts": [
    {
      "username": "my.user@gmail.com",
      "password": "secret",
      "server": "my.imap.example.com",
      "local_path": "/path/to/backup/root",
      "folders": [
        {"name": "[Gmail]/All Mail"},
        {"name": "my_folder"}
      ],
      "connection_options": {
        "ssl": {"verify_mode": 0},
        "port": 993
      }
    }
  ]
}
```

# Security

Note that email usernames and passwords are held in plain text
in the configuration file.

The directory ~/.imap-backup, the configuration file and all backup
directories have their access permissions set to only allow access
by your user. This is not done on Windows - see below.

## Windows

Due to the complexity of managing permissions on Windows,
directory and file access permissions are not set explicity.

A pull request that implements permissions management on Windows
would be welcome!

# Run Backup

Manually, from the command line:

```shell
$ imap-backup
```

Alternatively, add it to your crontab.

# Result

Each folder is saved to an mbox file.
Alongside each mbox is a file with extension '.imap', which lists the source IMAP
UIDs to allow a full restore.

# Local commands

There a various commands for viewing local backup status.

To view the list, use

```shell
$ imap_backup help local
```

# Troubleshooting

If you have problems:

1. ensure that you have the latest release,
2. turn on debugging output:

```json
{
  "accounts":
  [
    ...
  ],
  "debug": true
}
```

# Restore

All missing messages are pushed to the IMAP server.
Existing messages are left unchanged.

This functionality requires that the IMAP server supports the UIDPLUS
extension to IMAP4.

# Other Usage

List IMAP folders:

```shell
$ imap-backup folders
```

Get statistics of emails to download per folder:

```shell
$ imap-backup status
```

# Design Goals

* Secure - use a local file protected by permissions
* Restartable - calculate start point based on already downloaded messages
* Standalone - do not rely on an email client or MTA

# Documentation

* [Development](./docs/development.md)
* [Restore](./docs/restore.md)
