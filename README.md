imap-backup
===========
Backup GMail (or other IMAP) accounts to disk

Basic Usage
===========

* Create ~/.imap-backup
* Run

    imap-backup

Usage
=====

Check connection:

    imap-backup --check

List IMAP folders:

    imap-backup --list

Design Goals
============

* Secure - use a local file protected by permissions
* Restartable - calculate start point based on alreadt downloaded messages
* Standards compliant - save emails in a standard format
* Standalone - does not rely on an email client or MTA

Similar Software
================

* https://github.com/thefloweringash/gmail-imap-backup
* https://github.com/mleonhard/imapbackup
* https://github.com/rgrove/larch - copies between IMAP servers

