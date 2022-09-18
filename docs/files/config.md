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
