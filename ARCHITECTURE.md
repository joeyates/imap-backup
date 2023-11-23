# Command Line

`imap-backup` is a command line application.

It is written in Ruby.

Comands are processed by Thor modules -
under the CLI namespace.

# Setup

The setup program uses the highline gem to
present its menu-driven interface.

# Serialization

In an attempt to use a standard format,
the program saves emails on disk in mboxrd
files.
The format was chosen for two reasons:
mboxrd does not suffer from the problems related to
serializing 'From ' headers and
the Thunderbird email client uses this format.

# Backup Strategies

The backup system saves a metadata file alongside
the mboxrd file.
This file contains information about each email:
its length and offest in the mboxrd file.
If this file is rewritten when each new messsage is downloaded,
the backup slows down progressively as the mailbox grows.
To avoid this problem, the default strategy is to only write
metadata at the end of the download for each folder.

# Mirroring

If an account is mirrord to another server,
the emails on each server are different.
In order to know which email on the mirror relates to
which email on the source account,
a map file is created.

# Rubocop

The project's code style is guaranteed by Rubocop rules.

# Tests

Tests use RSpec. There are three types:
unit, integration ("feature") and performance.

The performance tests are not for normal use -
they are extremely slow, taking many hours to complete.

The intention is to have almost complete coverage
on two levels - unit and integration.

The integration tests run the application using the
aruba gem.

These tests make connections to two containers
running dovecot and postfix. This allows simulation
of mirroring and migrations.

# Documentation

This project has two READMEs:

* The {file:.github/README.md GitHub README} the end-user documentation which appears
  on GitHub,
* {file:README.md} - the developer documentation.
