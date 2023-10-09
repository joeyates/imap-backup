# This is a [jq](https://jqlang.github.io/jq/) script
# It can be used to list the accounts and folders
# that have errors when running `imap-backup local check`
# Usage:
#   imap-backup local check -c my_config.json --format json | jq -f contrib/list-failures-in-local-check.jq

map(
  # Save references for later
  . as {account: $account, folders: $folders}
  | $folders
  # Get a list of folders which have errors
  | map(
    select(.result != "OK")
  )
  # Save a reference to any errors
  | . as $errors
  # Skip accounts without errors
  | select(length > 0)
  # List the errors
  | [$account, $errors]
)

