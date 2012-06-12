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

    gem install 'imap-backup'

# Basic Usage

* Create ~/.imap-backup directory and configuration file

```shell
$ cd
$ mkdir .imap-backup
$ chmod 0700 .imap-backup
$ cd .imap-backup
$ touch config.json
$ chmod 0600 config.json
```

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

* Run

    imap-backup

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

