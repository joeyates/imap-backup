# FAQ

# How does restore work?

Backed-up emails are pushed to the IMAP server.
If there are clashes, folders are renamed.

# What are all these 'INBOX.12345' files?

If, when the backup is launched, the IMAP server contains a folder with
the same name, but different history to the local backup, the local
emails cannot simply be added to the existing folder.

In this case, a numeric suffix is added to the **local** folder,
before it is restored.

In this way, old and new emails are kept separate.

# Will my email get overwritten?

No.

Emails are identified by folder and a specific email id. Any email that
is already on the server is skipped.

## How do I restore to a different service?

It is best to use the `migrate` command in this case.
