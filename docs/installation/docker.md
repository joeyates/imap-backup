# Running in docker

These instructions do not include any guidance for building or testing the Docker image - for those, please see the [dev](dev) folder

```sh
docker run -v ./local-settings-path:/config -v ./local-backup-path:/path/to/backup/root --user $(id -u):$(id -g) ghcr.io/joeyates/imap-backup imap-backup --config /config/config.json
```