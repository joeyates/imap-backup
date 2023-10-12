# Running in docker

These instructions do not include any guidance for building or testing the Docker image - for those, please see the [dev/container](dev/container) folder

## setup
The docker containers by default mount the `/backup` folder to your local `./backup` folder. If you would like to change either, please adjust the compose or docker-run commands accordingly
```yml
volumes:
  - ./local-backup-path:/container-backup-path
  - ./local-settings-path:/container-settings-path
```

## docker/podman compose

Out of the box, running
```sh
# docker-cli-compose
$ docker compose up -f docker/compose.yml -d
# legacy docker-compose
$ docker-compose up -f docker/compose.yml -d
# podman
$ podman-compose up -f docker/compose.yml -d
```

## docker compose-less

If you would like to run the backup as a one-shot or as a service, the compose can be adapted to a Docker run command

```sh
export ID=$(id -u)
docker run -v ./config:/config -v ./backup:/backup --user $ID ghcr.io/joeyates/imap-backup imap-backup --config /config/config.json
```

