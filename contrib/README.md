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
