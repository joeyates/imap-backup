# imap-backup API Documentation

![Version](https://img.shields.io/gem/v/imap-backup?label=Version&logo=rubygems)
[![Build Status](https://github.com/joeyates/imap-backup/actions/workflows/main.yml/badge.svg)][CI Status]
![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/joeyates/b54fe758bfb405c04bef72dad293d707/raw/coverage.json)
![License](https://img.shields.io/github/license/joeyates/imap-backup?colour=brightgreen&label=License)
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

# Repository

After cloning the repo, run the following command to get
better `git blame` output:

```sh
git config --local blame.ignoreRevsFile .git-blame-ignore-revs
```

# Testing

## Feature Specs

Specs under `specs/features` are integration specs.
Some of these specs run against two local IMAP servers
controlled by Podman (or Docker) Compose.

Start them before running the test suite

```sh
$ podman-compose -f dev/compose.yml up -d
```

or, with Docker

```sh
$ docker-compose -f dev/compose.yml up -d
```

Then, run all specs

```sh
$ rspec
```

To exclude container-based tests

```sh
$ rspec --tag ~container
```

To run **just** the feature specs

```sh
rspec spec/features/**/*_spec.rb
```

## Full Test Run

The full test run includes RSpec specs **and** Rubocop checks

```sh
rake
```

# Test Debugging

The feature specs are run 'out of process' via the Aruba gem.
In order to see debugging output from the process,
use `last_command_started.output`.

# Older Rubies

A Containerfile is available to allow testing with all available Ruby versions,
see the README in the `dev` directory.

# Performance Specs

```sh
PERFORMANCE=1 rspec --order=defined
```

Beware: the performance spec (just backup for now) takes a very
long time to run, approximately 24 hours!

# Access Docker imap server

```ruby
require "net/imap"
require_relative "spec/features/support/30_email_server_helpers"

include EmailServerHelpers

test_connection = test_server_connection_parameters

test_imap = Net::IMAP.new(test_connection[:server], test_connection[:connection_options])
test_imap.login(test_connection[:username], test_connection[:password])

message = "From: #{test_connection[:username]}\nSubject: Some Subject\n\nHello!\n"
response = test_imap.append("INBOX", message, nil, nil)

test_imap.examine("INBOX")
uids = test_imap.uid_search(["ALL"]).sort

fetch_data_items = test_imap.uid_fetch(uids, ["BODY[]"])
```

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
