[![Build Status](https://circleci.com/gh/joeyates/imap-backup.svg?style=svg)][Continuous Integration]
[![Source Analysis](https://codeclimate.com/github/joeyates/imap-backup/badges/gpa.svg)](https://codeclimate.com/github/joeyates/imap-backup)
[![Test Coverage](https://codeclimate.com/github/joeyates/imap-backup/badges/coverage.svg)](https://codeclimate.com/github/joeyates/imap-backup/coverage)

# imap-backup

*Backup GMail (or other IMAP) accounts to disk*

  * [Source Code]
  * [API documentation]
  * [Rubygem]
  * [Continuous Integration]

[Source Code]: https://github.com/joeyates/imap-backup "Source code at GitHub"
[API documentation]: http://rubydoc.info/gems/imap-backup/frames "RDoc API Documentation at Rubydoc.info"
[Rubygem]: http://rubygems.org/gems/imap-backup "Ruby gem at rubygems.org"
[Continuous Integration]: https://circleci.com/gh/joeyates/imap-backup "Build status by CirceCI"

# GMail

To use imap-backup with GMail, you will need to enable 'App passwords' on your account.

# Installation

```shell
$ gem install 'imap-backup'
```

# Setup

In order to do backups, you need to add accounts via a menu-driven command
line program:

Run:

```shell
$ imap-backup setup
```

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
by your user.

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

# Similar Software

* https://github.com/OfflineIMAP/offlineimap

# Testing

## Integration Tests

Integration tests (feature specs) are run against a Docker image
(antespi/docker-imap-devel:latest).

In one shell, run the Docker image:

```sh
$ docker run \
  --env MAIL_ADDRESS=address@example.org \
  --env MAIL_PASS=pass \
  --env MAILNAME=example.org \
  --publish 8993:993 \
  antespi/docker-imap-devel:latest
```

```sh
$ rake
```

To exclude Docker-based tests:

```sh
rake no-docker
```

or

```sh
$ rspec --tag ~docker
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
