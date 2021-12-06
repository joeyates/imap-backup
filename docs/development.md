# Testing

## Integration Tests

Integration tests (feature specs) are run against a Docker image
(antespi/docker-imap-devel:latest).

In one shell, run the Docker image:

```sh
$ docker run \
  --env MAIL_ADDRESS=address@example.org \
  --env MAIL_PASS=pass \
  --env MAILNAME=example.org \
  --publish 8993:993 \
  antespi/docker-imap-devel:latest
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

REQUESTED_ATTRIBUTES = ["RFC822", "FLAGS", "INTERNALDATE"].freeze
fetch_data_items = imap.uid_fetch(uids, REQUESTED_ATTRIBUTES)
```

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
