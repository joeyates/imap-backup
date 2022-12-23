# Build an Image

```sh
podman build --file docker/Dockerfile-[VERSION] --tag imap-backup:VERSION .
```

# Run an Image

```sh
podman run -ti imap-backup:VERSION
```
