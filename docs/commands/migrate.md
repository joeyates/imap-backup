# Migrate

```sh
imap-backup migrate SOURCE_EMAIL DESTINATION_EMAIL [OPTIONS]
```

This command copies backed up emails for one account (the "source")
to another account (the "destination").

# Options

* `--reset` - delete all messages from destination folders before uploading,
* `--source-delimiter` - the separator between the elements of folders names
  on the source server, defaults to `/`,
* `--source-prefix` - optionally, a prefix element to remove from the name
  of source folders,
* `--destination-delimiter` - the separator between the elements of folder
  names on the destination server, defaults to `/`,
* `--destination-prefix` - optionally, a prefix element to add before names
  on the destination server.

# FAQ

## How to use delimiters and prefixes?

For details of the delimiter and prefix options,
see [the note about delimiters and prefixes](/docs/delimiters-and-prefixes.md).

## How to migrate to a new server while keeping the same e-mail address?

See [this note on the topic](/docs/migrate-server-keep-address.md).
