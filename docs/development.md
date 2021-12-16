# Testing

## Integration Tests

Integration tests (feature specs) are run against a local IMAP server
controlled by Docker Compose, which needs to be started
before running the test suite.

```sh
$ docker-compose up -d
```

```sh
$ rake
```

To exclude Docker-based tests:

```sh
rake no-docker
```

or

```sh
$ rspec --tag ~docker
```

## Access Docker imap server

```ruby
require "net/imap"

imap = Net::IMAP.new("localhost", {port: 8993, ssl: {verify_mode: 0}})
username = "address@example.org"
imap.login(username, "pass")

message = "From: #{username}\nSubject: Some Subject\n\nHello!\n"
response = imap.append("INBOX", message, nil, nil)

imap.examine("INBOX")
uids = imap.uid_search(["ALL"]).sort

fetch_data_items = imap.uid_fetch(uids, ["BODY[]"])
```

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
