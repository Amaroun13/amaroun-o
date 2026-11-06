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
Boot enabled. NVIDIA's third-party kernel module needs a machine-specific MOK;
an OCI image cannot enroll a certificate in firmware automatically.

After the first boot, create and enroll the akmods key on the target:

```bash
sudo kmodgenca
sudo mokutil --import /etc/pki/akmods/certs/public_key.der
sudo systemctl reboot
```

Confirm the MOK enrollment in the firmware screen. After booting again, build
and install the NVIDIA module for the running kernel:

```bash
sudo akmods --force --kernels "$(uname -r)"
sudo depmod -a
sudo modprobe nvidia
```

The private MOK key is generated and kept on the target; it is never stored in
GitHub Actions or in the OCI image.
