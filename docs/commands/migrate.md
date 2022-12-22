# Migrate

```sh
imap-backup migrate SOURCE_EMAIL DESTINATION_EMAIL
```

This command copies backup emails for one account (the "source")
to another account (the "destination").

# Options

* `reset` - delete all messages from destination folders before uploading,
* `source-delimiter` - the separator between the elements of folders names on the source server, defaults to `/`,
* `source-prefix` - optionally, a prefix element to remove from the name of source folders,
* `destination-delimiter` - the separator between the elements of folders names on the destination server, defaults to `/`,
* `destination-prefix` - optionally, a prefix element to add before names on the destination server.

# Migrate Requires a Empty Destination Account

Usually, you should migrate to an account with empty folders.
Before migrating each folder, `imap-backup` checks if the destination
folder is empty.
If it finds a non-empty destination folder, it halts with an error.
If you are sure that these destination emails can be deleted,
use the `--reset` option. In this case, all existing emails are
deleted before uploading the migrated emails.

# Delimiters and Prefixes

For details of the delimiter and prefix options,
see [the note about delimiters and prefixes](../delimiters-and-prefixes.md).
