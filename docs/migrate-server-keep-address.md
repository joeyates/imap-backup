# Migrate to a new e-mail server while keeping your existing address

While switching e-mail provider (from provider `A` to `B`),
you might want to keep the same address (`mymail@domain.com`),
and restrieve all your existing e-mails on your new server `B`.
`imap-backup` can do that too!

1. Backup your e-mails: use [`imap-backup setup`](/docs/commands/setup.md)
  to setup connection to your old provider `A`,
  then launch [`imap-backup backup`](/docs/commands/backup.md).
1. Actually switch your e-mail service provider (update your DNS MX and all that...).
1. It is best to use [`imap-backup migrate`](/docs/commands/migrate.md)
  and not [`imap-backup restore`](/docs/commands/restore.md) here,
  but both the source and the destination have the same address...
  You need to manually rename your old account first:

    1. Modify your configuration file manually
      (i.e. not via `imap-backup setup`) and
      rename your account to `mymail-old@domain.com`:

        ```diff
          "accounts": [
            {
        -     "username": "mymail@domain.com",
        +     "username": "mymail-old@domain.com",
              "password": "...",
        -     "local_path": "/some/path/.imap-backup/mymail_domain.com",
        +     "local_path": "/some/path/.imap-backup/mymail-old_domain.com",
              "folders": [...],
              "server": "..."
            }
        ```

    1. Rename the backup directory from `mymail_domain.com`
      to `mymail-old_domain.com`.

1. Set up a new account giving access to the new provider `B`
  using `imap-backup setup`.
1. Now you can use `imap-backup migrate`, optionnally adapting
  [delimiters and prefixes configuration](/docs/delimiters-and-prefixes.md)
  if need be:

		imap-backup migrate mymail-old@domain.com mymail@domain.com [options]
