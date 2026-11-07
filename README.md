# amaroun-o

Fedora Atomic (bootc) image built from `quay.io/fedora/fedora-bootc:45`.

The image is cryptographically sealed during the container build. The sealed
UKI contains the composefs digest of the root filesystem and is signed with
the Secure Boot certificate. The systemd-boot EFI binary is signed with the
same certificate. GitHub Actions also signs the published OCI image with
Cosign using GitHub's OIDC identity.

## Build locally

```bash
podman build --format=oci \
  --secret id=secureboot_key,src=private_key.pem \
  --secret id=secureboot_cert,src=certificate.pem \
  -t localhost/amaroun-o:latest \
  -f Containerfile .
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

The Fedora base provides the bootc kernel and systemd-boot components. The
GitHub Actions build signs the NVIDIA module with the
certificate supplied in the `SECUREBOOT_CERT` secret and the matching private
key in `SECUREBOOT_KEY`. The same key signs the sealed UKI and systemd-boot.
The private key is available only in build secret mounts and is not stored in
the OCI image.

Create these repository secrets before starting the workflow:

- `SECUREBOOT_KEY`: PEM-encoded private key
- `SECUREBOOT_CERT`: PEM-encoded X.509 certificate

The OCI signature is keyless. It is created and verified by the workflow using
GitHub Actions OIDC; no Cosign private key is stored in repository secrets.

Before the first boot, export the public certificate used by the build to a
DER file and enroll it in the target firmware:

```bash
openssl x509 -in certificate.pem -outform DER -out public_key.der
sudo mokutil --import public_key.der
sudo systemctl reboot
```

Verify the published OCI signature locally (Cosign must be installed):

```bash
cosign verify \
  --certificate-identity-regexp \
    '^https://github.com/Amaroun13/amaroun-o/.github/workflows/build.yml@refs/heads/main$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/amaroun13/amaroun-o:latest
```

Confirm the MOK enrollment in the firmware screen. Then install the image:

```bash
sudo bootc switch ghcr.io/amaroun13/amaroun-o:latest
sudo systemctl reboot
```

The Secure Boot private key is provided only to the build and is never stored
in GitHub Actions or in the OCI image.
