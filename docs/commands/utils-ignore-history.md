<!--
# @title command: 'utils ignore-history'
-->
# Utils Ignore History

```sh
imap-backup utils ignore-history EMAIL
```

If you only want to download future emails for an account and skip
all emails that have been received so far, this command
fills the backup with small dummy emails for each existing email.

The resulting backup is much smaller as emails up to a certain date
do not contain the real content, which, especially if there are attachments,
may amount to a lot of data.
