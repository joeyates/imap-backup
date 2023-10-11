# Running in docker

These instructions do not include any guidance for building or testing the Docker image - for those, please see the [dev/container](dev/container) folder

## setup

After setting up your config, your directory structure should look like this. Make sure that your backup destination is prefixed with `/backup` or change your local path accordingly.

If you would only like to run with docker compose, then [dev/container/compose.yml](dev/container/compose.yml) can be copied out of the directory and used independently.

```
backup/
config/
  config.json
compose.yml (optional)
```

## docker/podman compose

Out of the box, running
```sh
# docker-cli-compose
$ docker compose up -f compose.yml -d
# legacy docker-compose
$ docker-compose up -f compose.yml -d
# podman
$ podman-compose up -f compose.yml -d
```
will read the configuration from `./config/config.json` and back up to `./backup`. This job can be restarted as new backups are needed 

## docker compose-less

If you would like to run the backup as a one-shot or as a service, the compose can be adapted to a oneline command

```sh
docker run -v ./config:/config -v ./backup:/backup --user $(id -u) ghcr.io/joeyates/imap-backup
```

