# Design Goals

* Secure - use a local file protected by permissions
* Restartable - calculate start point based on already downloaded messages
* Standalone - do not rely on an email client or MTA

# Testing

## Feature Specs

Specs under `specs/features` are integration specs run against a local IMAP server
controlled by Docker Compose.
Before running the test suite, it needs to be started:

```sh
$ docker-compose up -d
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

### Debugging

The feature specs are run 'out of process' via the Aruba gem.
In order to see debugging output from the process,
use `last_command_started.output`.

## Access Docker imap server

```ruby
require "net/imap"

imap = Net::IMAP.new("localhost", {port: 8993, ssl: {verify_mode: 0}})
username = "address@example.com"
imap.login(username, "pass")

message = "From: #{username}\nSubject: Some Subject\n\nHello!\n"
response = imap.append("INBOX", message, nil, nil)

imap.examine("INBOX")
uids = imap.uid_search(["ALL"]).sort

fetch_data_items = imap.uid_fetch(uids, ["BODY[]"])
```

# Older Ruby Versions

Dockerfiles are available for all the supported Ruby versions,
see the `docker` directory.

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
