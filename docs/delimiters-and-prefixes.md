# Delimiters and Prefixes

A simple folder name is `Friends`.

Most email servers allow you to put folders inside other folders.

On most email servers, the parts of a folder's name are separated with a `/` character.
So you might have `People/Friends`.

On the other hand, some email servers use a `.`, giving `People.Friends`.

Some email servers keep most email in a parent folder, often `INBOX`, so the above folder
would be `INBOX/People/Friends`.

The `migrate` and `mirror` commands provide options to help "translate" between
the behaviour of the source and destination servers.
