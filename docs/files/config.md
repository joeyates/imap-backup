<!--
# @title files: 'config.json'
-->
By default, imap-backup's configuration is stored as `~/.imap-backup/config.json`.
It is a JSON file.
You can use a configuration file in another location by passing the
`--config PATH` parameter to any command.

A typical configuration file looks like this:

```json
{
  "accounts": [
    {
      "username": "my.user@gmail.com",
      "password": "secret",
      "local_path": "/path/to/backup/root",
      "folders":
        [
          {"name": "[Gmail]/All Mail"},
          {"name": "my_folder"}
        ]
    }
  ]
}
```

# Security

Note that email usernames and passwords are held in plain text
in the configuration file.

You can avoid having your password held in plain text in the configuration file
by setting an environment variable and passing the `--env` (or `-e`) parameter
to the `backup` command. Here is an example configuration file:

```json
{
  "accounts": [
    {
      "username": "my.user@ikmail.com",
      "password": "$PASSWORD",
      "local_path": "/path/to/backup/root",
      "folders": [
        {"name": "Drafts"},
        {"name": "Spam"},
        {"name": "Trash"},
      ],
      "folder_blacklist": true,
      "server": "imap.infomaniak.com",
      "connection_options": {
        "port": 993
      },
      "multi_fetch_size": 10
    }
  ],
  "download_strategy": "delay_metadata"
}
```

> [!NOTE]
> If the environment variable is not set – `$PASSWORD` in the above example –
> you will get a password prompt when running `imap-backup backup --env`.
> **Your password will not be stored**, it is entered temporarily and never
> written to disk.

The directory ~/.imap-backup, the configuration file and all backup
directories have their access permissions set to only allow access
by your user. This is not done on Windows - see below.

If you choose a custom path for your configuration file,
make sure that is not accessible by other users.

## Windows

Due to the complexity of managing permissions on Windows,
directory and file access permissions are not set explicity.

A pull request that implements permissions management on Windows
would be welcome!
