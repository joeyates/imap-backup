---
title: Fix mboxrd Quote Serialization Bug
description: Fix incorrect mboxrd quoting that affects `From:` headers, bump the imap metadata version to 3.1, and migrate version 3 files on load.
branch: bugfix/fix-mboxrd-quote-serialization
---

## Overview

The mboxrd serializer incorrectly adds a `>` prefix to any line starting with `From` (including `From:` headers), when it should only quote lines starting with `From ` (with a trailing space). The same bug exists in the reverse direction on load. This results in corrupted email bodies. The fix corrects both regexes, bumps the metadata version to 3.1, and adds a migration path so that existing version 3 mbox files are handled using the old (buggy) deserialization logic.

## Tasks

- [ ] In `lib/imap/backup/serializer/imap.rb`, bump `CURRENT_VERSION` to `3.1` and update `LOADABLE_VERSIONS` to `[3, 3.1]`
- [ ] In `lib/imap/backup/serializer/imap.rb`, add a `case data[:version]` branch in `ensure_loaded`: for `CURRENT_VERSION` load normally; for `3` load messages using `from_serialized_v3` and set `@version = CURRENT_VERSION`
- [ ] In `lib/imap/backup/email/mboxrd/message.rb`, fix `add_extra_quote` regex from `/\n(>*From)/` to `/\n(>*From )/`
- [ ] In `lib/imap/backup/email/mboxrd/message.rb`, fix `clean_serialized` regex from `/^>(>*From)/` to `/^>(>*From )/`
- [ ] In `lib/imap/backup/email/mboxrd/message.rb`, add `clean_serialized_v3` (using the old regex) and `from_serialized_v3` class methods
- [ ] Ask the user for feedback on the state of the implementation and carry out any requested corrections.
- [ ] Mark the plan as "done".

## Principal Files

- lib/imap/backup/email/mboxrd/message.rb
- lib/imap/backup/serializer/imap.rb
- spec/unit/email/mboxrd/message_spec.rb
- spec/unit/serializer/imap_spec.rb

## Acceptance Criteria

- `add_extra_quote` only prefixes lines beginning with `From ` (space), not `From:` or other `From`-prefixed tokens
- `clean_serialized` only strips a leading `>` from lines beginning with `>From ` (space)
- `CURRENT_VERSION` is `3.1` and `LOADABLE_VERSIONS` includes both `3` and `3.1`
- When a version 3 file is loaded, messages are deserialized with the old logic and `@version` is set to `3.1` so the next save upgrades the file
- All existing tests pass; new tests cover the corrected and legacy deserialization behaviour
