Configuration is stored in a JSON file.

The format is documented [here](files/config.md).

# Folders

By default, all folders are backed-up. You can override this by choosing
specific folders.

# Connection options

You can override the parameters passed to `Net::IMAP` with `connection_options`.

See the Ruby Standard Library documentation for `Net::IMAP` of details of [supported parameters](https://ruby-doc.org/stdlib-3.1.2/libdoc/net-imap/rdoc/Net/IMAP.html#method-c-new).

Specifically, if you are using a self-signed certificate and get SSL errors, e.g.
`certificate verify failed`, you can choose to not verify the TLS connection.

Connection options can be entered via `imap-backup setup` as JSON.

Choose the account, then 'modify connection options'.

For example:

![Entering connection options as JSON](./images/entering-connection-options-as-json.png "Entering connection options as JSON")
