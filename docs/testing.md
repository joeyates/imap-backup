# Setup

Specs under `spec/features` are integration specs.
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

# Invocations

Run all specs

```sh
$ rake spec
```

Run **just** the unit specs

```sh
$ rake spec_unit
```

Run **just** the feature specs

```sh
$ rake spec_feature
```

To exclude the slow container-based tests

```sh
$ rake spec_non_container
```

## Full Test Run

The full test run includes RSpec specs **and** Rubocop checks

```sh
rake test
```

# Debugging

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
