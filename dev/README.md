# Containerized Rubies

This directory contains some files that allow experimenting with
any desired Ruby version locally.

This is especially useful for older, deprecated Ruby versions
which are often difficult to install due to openssl
compatibility problems.

The supplied `dev/ruby-compose.yml` starts the same
two IMAP servers that are run under development and CI
alongside a container with your chosen Ruby version.

This container has the project root available as the `/app`
directory so that you can run tests and edit code.

# Start Containers

Do the following from the project's root directory:

```sh
export RUBY_VERSION=[VERSION]
podman-compose --file dev/ruby-compose.yml build
podman-compose --file dev/ruby-compose.yml up -d
podman attach imap-backup
```

...and stop the server afterwards:

```sh
podman-compose --file dev/ruby-compose.yml down
```

# Setup Project

It's best to delete any `Gemfile.lock` you may have
in order to get gem versions which
are compatible with the Ruby version you are using.

```sh
rm Gemfile.lock
bundle install
```

As the BUNDLE_BINSTUBS environment variable is set,
we get a version of imap-backup that can be invoked
without prepending `bundle exec`.

The `PATH` environment variable includes `/app/bin/stubs`,
so you can invoke imap-backup directly

```sh
imap-backup help
```

# Run tests

```sh
rake
```

# Connect to the Test IMAP Server

An example file `dev/config.json` is supplied.

The following should produce a list of folders

```sh
imap-backup remote folders address@example.com -c dev/config.json
```

You can use the test helpers to interact with the test IMAP servers:

```sh
$ pry
> require "rspec"
> require_relative "spec/features/support/30_email_server_helpers"
> include EmailServerHelpers
> test_server.send_email("INBOX", uid: 123, from: "address@example.org", subject: "Test 1", body: "body 1\nHi")
```
