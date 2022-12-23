# Build an Image

```sh
podman build --file docker/Dockerfile --build-arg=[VERSION] --tag imap-backup:VERSION .
```

# Run an Image

```sh
podman run -ti imap-backup:VERSION
```
