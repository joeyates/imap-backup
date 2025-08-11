<!--
# @title command: 'backup'
-->
# Backup

```sh
imap-backup backup
```

This command runs the backup operation using information provided
by a configuration file created using `imap-backup setup`.

By default, emails for all *configured* accounts are copied to disk.

The backup is incremental and interruptible, so backups will not get messed up
if your connection goes down during an operation.

# Single Account Backups

As an alternative, if you only want to backup a single account,
you can pass all the necessary parameters directly to the `single backup` command
(see the [`single backup`](./single-backup.md) docs).

# Serialized Format

Emails are stored on disk in [Mbox files](../files/mboxrd.md), one for each folder,
with metadata stored in [Imap files](../files/imap.md).

The Imap file contains information about the email messages stored in the Mbox file.
For each, it has the offset to the start of the message and its length.

# Output

Verbose output can be configured by adding the `--verbose` (or `-v`) parameter.
Add that parameter twice will also show all network traffic between
imap-backup and the IMAP server.
