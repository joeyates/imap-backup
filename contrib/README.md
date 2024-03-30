# contrib

This directory contains contributed scripts that relate to
imap-backup

# import-accounts-from-csv

This script reads a CSV file and merges the supplied
information into an imap-backup configuration file.

Depending on how your CSV file is structured,
you will probably need to modify the `COLUMNS` structure in the script.

While importing, it checks that the provided credentials
ans connection parameters work.

An example CSV file `contrib/example_users.csv` is provided.

You can try out the script as follows:

```sh
contrib/import-accounts-from-csv --csv contrib/example_users.csv --config example-config.json --verbose
```

# import-messages-from-thunderbird

This script imports all messages from a Thunderbird folder.

Obviously, Thunderbird must be installed and the folder in question must
have the Thunderbird setting "Select this folder for offline use".

```sh
contrib/import-thunderbird-folder --config example-config.json --verbose
```
