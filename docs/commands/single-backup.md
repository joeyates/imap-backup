# Direct Config-less Backup

This command is an alternative to the `imap-backup backup` command.
It lets you back up a single email account without relying on a configuration file.

To do so, you pass all the relevant settings as command-line parameters.

For example

```sh
imap-backup single backup --username me@example.com --password mysecret --server imap.example.com
```

As putting your password in a command line is obviously problematic for security
reasons, there are alternatives to the `--password` parameter,
see `imap-backup help direct` for a full list of parameters.
