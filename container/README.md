# Runnable imap-backup container

This Containerfile is used by the `publish-image`
GitHub action. It creates an image which is pushed
to GitHub packages. The image can be run via
Podman or Docker in order to use imap-backup without
installing anything else.

# Build in development

The image can be build in development as follows

```sh
export GIT_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
podman build \
  --file container/Containerfile \
  --label imap-backup:latest \
  --ignorefile ./container/.containerignore \
  .
```
