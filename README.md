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

The base Fedora kernel and bootloader are signed by Fedora and boot with Secure
Boot enabled. The GitHub Actions build signs the NVIDIA module with the
certificate supplied in the `SECUREBOOT_CERT` secret and the matching private
key in `SECUREBOOT_KEY`. The private key is available only in the build step
and is not stored in the OCI image.

Create these repository secrets before starting the workflow:

- `SECUREBOOT_KEY`: PEM-encoded private key
- `SECUREBOOT_CERT`: PEM-encoded X.509 certificate

Before the first boot, export the public certificate used by the build to a
DER file and enroll it in the target firmware:

```bash
openssl x509 -in certificate.pem -outform DER -out public_key.der
sudo mokutil --import public_key.der
sudo systemctl reboot
```

Confirm the MOK enrollment in the firmware screen. Then install the image:

```bash
sudo bootc switch ghcr.io/amaroun13/amaroun-o:latest
sudo systemctl reboot
```

The private MOK key is generated and kept on the target; it is never stored in
GitHub Actions or in the OCI image.
