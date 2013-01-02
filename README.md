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

    $ gem install 'imap-backup'

# Setup

Run:

    $ imap-backup setup

The setup system is a menu-driven command line application.

It creates ~/.imap-backup directory and configuration file. E.g.:

```
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

```
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


# Security

Note that email usernames and passwords are held in plain text
in the configuration file.

The directory ~/.imap-backup, the configuration file and all backup
directories have their access permissions set to only allow access
by your user.

# Run Backup

Manually, from the command line:

    $ imap-backup

Altertatively, add it to your crontab.

# Other Usage

List IMAP folders:

    imap-backup folders

Get statistics of emails to download per folder:

    imap-backup status

# Design Goals

* Secure - use a local file protected by permissions
* Restartable - calculate start point based on already downloaded messages
* Standalone - do not rely on an email client or MTA

# Similar Software

* https://github.com/thefloweringash/gmail-imap-backup
* https://github.com/mleonhard/imapbackup
* https://github.com/rgrove/larch - copies between IMAP servers

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

