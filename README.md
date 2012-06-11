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

* Create ~/.imap-backup

```
    {
      accounts:
      [
        {
          username: "my.user@gmail.com",
          password: "secret",
          local_path: "/path/to/backup/root",
          folders:
            [
              {name: "[Gmail]/All Mail"},
              {name: "my_folder"}
            ]
        }
      ]
    }
```

* Run

    imap-backup

# Usage

Check connection:

    imap-backup --check

List IMAP folders:

    imap-backup --list

# Design Goals

* Secure - use a local file protected by permissions
* Restartable - calculate start point based on alreadt downloaded messages
* Standards compliant - save emails in a standard format
* Standalone - does not rely on an email client or MTA

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

