FROM quay.io/fedora/fedora-bootc:45 AS rootfs

RUN dnf5 install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

RUN dnf5 install -y \
        akmod-nvidia \
        akmods \
        flatpak \
        gcc \
        git \
        htop \
        kernel-devel-matched \
        make \
        mokutil \
        nano \
        openssl \
        tmux \
        xorg-x11-drv-nvidia-cuda \
    && dnf5 clean all \
    && rm -rf /var/cache/dnf

RUN --mount=type=secret,id=secureboot_key \
    --mount=type=secret,id=secureboot_cert \
    set -euxo pipefail \
    && install -Dm600 /run/secrets/secureboot_key /etc/pki/akmods/private/private_key.priv \
    && openssl x509 -in /run/secrets/secureboot_cert -outform DER \
        -out /etc/pki/akmods/certs/public_key.der \
    && for kernel in /usr/lib/modules/*; do \
        [ -d "$kernel" ] || continue; \
        kver="${kernel##*/}"; \
        akmods --force --kernels "$kver"; \
    done \
    && depmod -a \
    && find /usr/lib/modules -type f \( -name '*.ko' -o -name '*.ko.xz' \) -print \
    && rm -f /etc/pki/akmods/private/private_key.priv

RUN flatpak remote-add --if-not-exists \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
    && flatpak install --system --assumeyes flathub org.mozilla.firefox \
    && flatpak repair --system \
    && rm -rf /var/tmp/* /var/cache/*

FROM rootfs AS split

RUN mkdir -p /kernel \
    && bootc container split-kernel-and-rootfs \
        --rootfs / \
        --output /kernel

FROM rootfs AS sealed-uki

RUN dnf5 install -y \
        sbsigntools \
        systemd-boot-unsigned \
        systemd-ukify \
    && dnf5 clean all \
    && rm -rf /var/cache/dnf

RUN --mount=type=bind,from=split,source=/kernel,target=/kernel,ro \
    --mount=type=bind,from=split,target=/target,ro \
    --mount=type=secret,id=secureboot_key \
    --mount=type=secret,id=secureboot_cert \
    set -euxo pipefail \
    && mkdir -p /out/uki \
    && kver="$(find /kernel -mindepth 1 -maxdepth 1 -type d -printf '%f\n')" \
    && bootc container ukify \
        --rootfs /target \
        --kernel-dir "/kernel/${kver}" \
        -- \
        --output "/out/uki/${kver}.efi" \
        --signtool sbsign \
        --secureboot-private-key /run/secrets/secureboot_key \
        --secureboot-certificate /run/secrets/secureboot_cert \
    && sbsign \
        --key /run/secrets/secureboot_key \
        --cert /run/secrets/secureboot_cert \
        --output /out/systemd-bootx64.efi \
        /usr/lib/systemd/boot/efi/systemd-bootx64.efi

FROM split

COPY --from=sealed-uki /out/uki/*.efi /boot/EFI/Linux/
COPY --from=sealed-uki /out/systemd-bootx64.efi \
    /usr/lib/systemd/boot/efi/systemd-bootx64.efi
