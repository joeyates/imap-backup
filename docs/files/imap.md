<!--
# @title files: '.mbox'
-->
Metadata about each folder is stored in `.imap` files.

The current version (version 3), looks like this:

```json
{
  "version": 3,
  "uid_validity": 1606316666,
  "messages": [
    {
      "uid": 1,
      "offset": 0,
      "length": 3736,
      "flags": ["Draft"]
    }
  ]
}
```

* version - the file format version,
* uid_validity - the [UIDVALIDITY attribute](https://www.rfc-editor.org/rfc/rfc3501#section-2.3.1.1) for the folder on the IMAP server,
* messages - metadata about the downloaded messages,
* uid - the message's unique identifier,
* offset - the offset of the start of the message in the accompanying `.mbox` file,
* length - the length of the serialized message,
* flags - any of the standard flags which were set in the message when last downloaded.
