# Mirror

```sh
imap-backup mirror SOURCE_EMAIL DESTINATION_EMAIL
```

This command makes a local copy of the source account and then copies
that to the destination account.

Exactly which folders are backed up (and mirrored) depends on how the account is set up.

Note that, anything on the destination account that is not on the source account gets deleted.

## Modes

If the local copy is in 'keep all' mode, the destination account will gradually have more and more emails.

On the other hand, if the local copy is in 'mirror' mode, the destination account will have the same emails
as the source account.

# Delimiters and Prefixes

For details of the delimiter and prefix options,
see [the note about delimiters and prefixes](../delimiters-and-prefixes.md).
