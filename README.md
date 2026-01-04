# imap-backup API Documentation

![Version](https://img.shields.io/gem/v/imap-backup?label=Version&logo=rubygems)
[![Build Status](https://github.com/joeyates/imap-backup/actions/workflows/main.yml/badge.svg)][CI Status]
![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/joeyates/b54fe758bfb405c04bef72dad293d707/raw/coverage.json)
![License](https://img.shields.io/github/license/joeyates/imap-backup?color=brightgreen&label=License)
[![Stars](https://img.shields.io/github/stars/joeyates/imap-backup?style=social)][GitHub Stars]
![Activity](https://img.shields.io/github/last-commit/joeyates/imap-backup/main)

[CI Status]: https://github.com/joeyates/imap-backup/actions/workflows/main.yml
[GitHub Stars]: https://github.com/joeyates/imap-backup/stargazers "GitHub Stars"

This is the developer documentation for imap-backup's **code**.

Usage documentation is on [GitHub](https://github.com/joeyates/imap-backup).

You can get an overview of the program's structure from the
{file:ARCHITECTURE.md ARCHITECTURE} file.

The {file:CHANGELOG.md CHANGELOG} has a history of the changes to the program.

# Design Goals

* Secure - use a local configuration file protected by permissions
* Restartable - calculate start point based on already downloaded messages
* Standalone - do not rely on an email client or MTA

# Development

See the [development documentation](/docs/development.md).

# Testing

See the [testing documentation](/docs/testing.md).

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
