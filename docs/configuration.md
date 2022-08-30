Configuration is stored in a JSON file.

The format is documented [here](./docs/files/config.json).

# Folders

By default, all folders are backed-up. You can override this by choosing
specific folders.

# Connection options

You can override the parameters passed to `Net::IMAP` with `connection_options`.

Specifically, if you are using a self-signed certificate and get SSL errors, e.g.
`certificate verify failed`, you can choose to not verify the TLS connection.

Connection options can be entered via `imap-backup setup` as JSON.

Choose the account, then 'modify connection options'.

For example:

![Entering connection options as JSON](./images/entering-connection-options-as-json.png "Entering connection options as JSON")
