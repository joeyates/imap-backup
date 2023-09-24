# container

This directory contains the files that allow experimenting with
any desired Ruby version locally.

This is especially useful for older, deprecated Ruby versions
which are often difficult to install due to openssl
compatibility problems.

# Start Container

Do the following from the project's root directory:

```sh
RUBY_VERSION=[VERSION] ID=$(id -u) docker-compose --file dev/container/compose.yml build
RUBY_VERSION=[VERSION] ID=$(id -u) docker-compose --file dev/container/compose.yml up -d
docker attach imap-backup
```

...and stop the server afterwards:

```sh
RUBY_VERSION=[VERSION] ID=$(id -u) docker-compose --file dev/container/compose.yml down
```

# Setup Project

It's best to delete any `Gemfile.lock` you may have
in order to get gem versions which
are compatible with the Ruby version you are using.

```sh
rm Gemfile.lock
bundle install
```

# Run tests

```sh
rake
```

# Invoke `imap-backup`

As the `BUNDLE_BINSTUBS` environment variable is set,
you can invoke imap-backup directly

```sh
imap-backup help
```

# Connect to the Test IMAP Server

An example file `dev/container/config.json` is supplied.

The following should produce a list of folders

```sh
imap-backup remote folders address@example.com -c dev/container/config.json
```

You can use the test helpers to interact with the test IMAP servers:

```sh
$ pry
> require "rspec"
> require_relative "spec/features/support/email_server"
> include EmailServerHelpers
> test_server.send_email("INBOX", uid: 123, from: "address@example.org", subject: "Test 1", body: "body 1\nHi")
```
