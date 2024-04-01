<!--
# @title command: 'copy'
-->
# Copy

```sh
imap-backup copy SOURCE_EMAIL DESTINATION_EMAIL
```

This command makes a local copy of the emails in the source account
and then copies them to the destination account.

Exactly which folders are backed up (and copied) depends on how the account is set up.

Specifically, the `folder inclusion mode (whitelist/blacklist)` and
`folders to include/exclude` list.

Note that, any messages on the destination account that is not on the source account
are left unchanged.

# Options

* `--source-delimiter` - the separator between the elements of folders names
  on the source server, defaults to `/`,
* `--source-prefix` - optionally, a prefix element to remove from the name
  of source folders,
* `--destination-delimiter` - the separator between the elements of folder
  names on the destination server, defaults to `/`,
* `--destination-prefix` - optionally, a prefix element to add before names
  on the destination server,
* `--automatic-namespaces` - works out the 4 parameters above by querying
  the source and destination IMAP servers.

# Delimiters and Prefixes

For details of the delimiter and prefix options,
see [the note about delimiters and prefixes](../delimiters-and-prefixes.md).
