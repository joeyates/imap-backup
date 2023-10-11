# Ruby version testing
This directory contains the files that allow experimenting with
any desired Ruby version locally.

This is especially useful for older, deprecated Ruby versions
which are often difficult to install due to openssl
compatibility problems.

## Start Container

Do the following from the project's root directory:

```sh
export RUBY_VERSION=[VERSION]
docker compose --file dev/imap-compose.yml up -d
docker compose --file dev/ruby-compose.yml up -d --build
docker attach imap-backup
```

...and stop the server afterwards:

```sh
docker compose --file dev/imap-compose.yml down
docker compose --file dev/ruby-compose.yml down
```

## Run tests
```sh
rake
```

## Invoke `imap-backup`
```sh
imap-backup help
```

# Connect to the Test IMAP Server

An example file `dev/container/config.json` is supplied.

The following should produce a list of folders

```sh
imap-backup remote folders address@example.com -c /app/config.json
```

You can use the test helpers to interact with the test IMAP servers:

```sh
$ pry
> require "rspec"
> require_relative "spec/features/support/30_email_server_helpers"
> include EmailServerHelpers
> test_server.send_email("INBOX", uid: 123, from: "address@example.org", subject: "Test 1", body: "body 1\nHi")
```
