# Build an Image

```sh
podman build --file docker/Dockerfile --build-arg RUBY_VERSION=[VERSION] --tag imap-backup:VERSION .
```

# Run an Image

```sh
podman run -ti imap-backup:VERSION
```
