# Run

```sh
RUBY_VERSION=[VERSION] ID=$(id -u) docker-compose --file container/compose.yml build
RUBY_VERSION=[VERSION] ID=$(id -u) docker-compose --file container/compose.yml up -d
docker attach imap-backup
```

..and stop the server afterwards:

```sh
RUBY_VERSION=[VERSION] ID=$(id -u) docker-compose --file container/compose.yml down
```

# Setup

It's best to delete any `Gemfile.lock` you may have
in order to get gem versions which
are compatible with the Ruby version you are using.

```sh
rm Gemfile.lock
bundle install
```

# Invoking `imap-backup`

As the BUNDLE_BINSTUBS environment variable is set,
you can invoke imap-backup directly

```sh
imap-backup help
```

# Connecting Test Server

An example file `container/config.json` is supplied.

The folowing should produce a list of folders

```sh
imap-backup remote folders me@example.com -c config.json
```
