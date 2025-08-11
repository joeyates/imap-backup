# Performance

The two performance-related settings are "Download strategy", which is a global setting, and "Multi-fetch size", which is an Account-level setting.

As with all performance tweaks, there are trade-offs.

# Overview

The defaults, which suit most machines and play nice with servers are:

* Download strategy: "delay writing metadata",
* Multi-fetch size: 1.

If you are using a resource-limited machine like 
a small virtual server or Raspberry Pi
to run your backups, you can change "Download strategy".

If your email provider supports it,
and you don't have tight memory limits,
increase "Multi-fetch size" for faster backups.

# Delay download writes

This is a global setting, affecting all account backups.

By default, `imap-backup` uses the "delay writing metadata" strategy.
As messages are being backed-up, the message *text*
is written to disk, while the related metadata is stored in memory.

While this uses a *little* more memory, it avoids rewiting a growing JSON
file for every message, speeding things up and reducing disk wear.

The alternative strategy, called "write straight to disk",
writes everything to disk as it is received.
This method is slower, but has the advantage
of using slightly less memory, which may be important on very
resource-limited systems, like Raspberry Pis.

# Multi-fetch Size

By default, during backup, each message is downloaded one-by-one.

Using this setting, you can download chunks of emails at a time,
potentially speeding up the process.

Using multi-fetch means that the backup process *will* use
more memory - equivalent to the size of the groups of messages
that are downloaded.

This behaviour may also exceed the rate limits on your email provider,
so it's best to check before cranking it up!
