# amaroun-o

Fedora Atomic (bootc) image built from `quay.io/fedora/fedora-bootc:45`.

## Build locally

```bash
podman build --format=oci -t localhost/amaroun-o:latest -f Containerfile .
```

GitHub Actions publishes the image as:

```text
ghcr.io/amaroun13/amaroun-o:latest
```

## Install

On a Fedora Atomic/bootc host:

```bash
sudo bootc switch ghcr.io/amaroun13/amaroun-o:latest
sudo systemctl reboot
```

The NVIDIA kernel module is built into the image by akmods. With Secure Boot
enabled, sign the generated module with a MOK key enrolled on the target
machine; private signing keys are deliberately not part of the OCI build.
