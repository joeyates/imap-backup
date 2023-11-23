<!--
# @title command: 'local check'
-->
# Local Integrity Check

```sh
imap-backup local check
```

This command checks the integrity of the local backup.

See the [backup command](./backup.md), for details.

For each account, each folder is listed, indicating whether
the `.imap` and `.mbox` files are corrupt or not.

# Options

* `config` - allows supplying a non-default path for the configuration file,
* `delete-corrupt` - deletes folders that are corrupt,
* `format` - passing `--format json` produces JSON output.
