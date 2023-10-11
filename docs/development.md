# Repository

After cloning the repo, run the following command to get
better `git blame` output:

```sh
git config --local blame.ignoreRevsFile .git-blame-ignore-revs
```

# Design Goals

* Secure - use a local file protected by permissions
* Restartable - calculate start point based on already downloaded messages
* Standalone - do not rely on an email client or MTA

# Development

A Dockerfile is available to allow testing with all available Ruby versions,
see the `dev/container` directory.

# Testing

## Feature Specs

Specs under `specs/features` are integration specs run against
two local IMAP servers controlled by Docker Compose.

Start them before running the test suite

```sh
$ docker-compose -f dev/docker-compose.yml up -d
```

or, with Podman

```sh
$ podman-compose -f dev/docker-compose.yml up -d
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

# Performance Specs

```sh
PERFORMANCE=1 rspec --order=defined
```

Beware: the performance spec (just backup for now) takes a very
long time to run, approximately 24 hours!

### Debugging

The feature specs are run 'out of process' via the Aruba gem.
In order to see debugging output from the process,
use `last_command_started.output`.

## Access Docker imap server

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
