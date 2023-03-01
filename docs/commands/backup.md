# Backup

```sh
imap-backup backup
```

This command runs the backup operation.

By default, emails for all configured accounts are copied to disk.

The backup is incremental and interruptable, so backups won't get messed up
if your connection goes down during an operation.

# Serialized Format

Emails are stored on disk in [Mbox files](../files/mboxrd.md), one for each folder,
with metadata stored in [Imap files](../files/imap.md).

The Imap file contains information about the email messages stored in the Mbox file.
For each, it has the offset to the start of the message and its length.

# Output

Verbose output can be [configured via the setup logging option](./setup.md#logging).
