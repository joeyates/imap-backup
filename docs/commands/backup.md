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

The backup is incremental and interruptible, so backups won't get messed up
if your connection goes down during an operation.

# Single Account Backups

As an alternative, if you only want to backup a single account,
you can pass all the necessary parameters directly to the `single backup` command
(see the [`single backup`](./single-backup.md) docs).

# Environment variables

For passwords only, it is possible to use an environment variable adding the
`--env` (or `-e`) parameter. In such case, the value entered as password with
`imap-backup setup`, or in the configuration file, must be a valid environment
variable name preceded with a dollar sign, for example `$PASSWORD`.

> [!NOTE]
> The regular expression for valid names is `/^\$([A-Za-z_][A-Za-z0-9_]*)$/`.

> [!NOTE]
> If the environment variable is not set you will get a password prompt when
> running `imap-backup backup --env`. **Your password will not be stored**,
> it is entered temporarily and never written to disk.

# Serialized Format

Emails are stored on disk in [Mbox files](../files/mboxrd.md), one for each folder,
with metadata stored in [Imap files](../files/imap.md).

The Imap file contains information about the email messages stored in the Mbox file.
For each, it has the offset to the start of the message and its length.

# Output

Verbose output can be configured by adding the `--verbose` (or `-v`) parameter.
Add that parameter twice will also show all network traffic between
imap-backup and the IMAP server.
