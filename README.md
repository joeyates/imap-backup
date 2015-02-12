# imap-backup [![Build Status](https://secure.travis-ci.org/joeyates/imap-backup.png)][Continuous Integration]

*Backup GMail (or other IMAP) accounts to disk*

  * [Source Code]
  * [API documentation]
  * [Rubygem]
  * [Continuous Integration]

[Source Code]: https://github.com/joeyates/imap-backup "Source code at GitHub"
[API documentation]: http://rubydoc.info/gems/imap-backup/frames "RDoc API Documentation at Rubydoc.info"
[Rubygem]: http://rubygems.org/gems/imap-backup "Ruby gem at rubygems.org"
[Continuous Integration]: http://travis-ci.org/joeyates/imap-backup "Build status by Travis-CI"

# Installation

```shell
$ gem install 'imap-backup'
```

# Setup

In order to do backups, you need to add accounts and specify the folders to backup.

Run:

```shell
$ imap-backup setup
```

The setup system is a menu-driven command line application.

It creates ~/.imap-backup directory and configuration file. E.g.:

```json
{
  "accounts":
  [
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
  "accounts":
  [
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

## Google Apps

* Enable IMAP access to your account via the GMail interface (Settings/Forwarding and POP/IMAP),
* In imap-backup setup, set the server to imap.gmail.com

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

* https://github.com/thefloweringash/gmail-imap-backup
* https://github.com/mleonhard/imapbackup
* https://github.com/rgrove/larch - copies between IMAP servers
* https://github.com/OfflineIMAP/offlineimap

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
