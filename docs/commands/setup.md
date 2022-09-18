# Setup

```sh
imap-backup setup
```

This command starts the interactive, menu-driven setup tool.

By default, the tool saves a configuration file in `~/.imap-backup/config.json`.

# Custom Configuration Path

You can override the location where the file is accessed and stored with the `--config` parameter:

```sh
imap-backup setup --config /home/me/.local/imap-backup/config.json
```

In this case, it is up to you to create the directory for the configuration file.

[More information about the configuration file is available in the specific documentation](../configuration.md).
