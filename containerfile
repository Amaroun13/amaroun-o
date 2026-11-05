# Použijeme oficiální základ pro Fedora 45 Bootc
FROM quay.io/fedora/fedora-bootc:45

# 1. Povolení RPM Fusion (nutné pro Nvidia ovladače) a COPR repozitáře
RUN dnf5 install -y https://rpmfusion.org \
                   https://rpmfusion.org && \
    dnf5 copr enable -y xabi08/MSI-EC

# 2. Odstranění RPM Firefoxu, který nechceme
RUN dnf5 remove -y firefox firefox-langpacks

# 3. Aktualizace systému a instalace aplikací včetně akmods, Nvidia a nástrojů pro podpis
RUN dnf5 upgrade -y && dnf5 install -y \
    htop \
    git \
    tmux \
    nano \
    flatpak \
    akmod-nvidia \
    xorg-x11-drv-nvidia-cuda \
    akmods \
    akmod-msi-ec \
    sbsigntools \
    && dnf5 clean all

# 4. Spuštění kompilace jaderných modulů (akmods) na pozadí buildu
# Bez tohoto kroku by se moduly kompilovaly až na vašem PC a nebyly by podepsané
RUN akmods --force

# 5. Přidání správného Flathub repozitáře a instalace Firefoxu
RUN flatpak remote-add --if-not-exists flathub https://flathub.org && \
    flatpak install --system -y flathub org.mozilla.firefox

# 6. SECURE BOOT PODPIS (Jádro, Shim zavaděč I VŠECHNY zkompilované moduly)
RUN --mount=type=secret,id=secureboot_key \
    --mount=type=secret,id=secureboot_cert \
    set -xeuo pipefail && \
    # A) Podepsání UEFI zavaděče (shim)
    sbsign --key /run/secrets/secureboot_key \
           --cert /run/secrets/secureboot_cert \
           /boot/efi/EFI/fedora/shimx64.efi --output /boot/efi/EFI/fedora/shimx64.efi && \
    # B) Podepsání všech Linuxových jader v /boot
    for kernel in /boot/vmlinuz-*; do \
        sbsign --key /run/secrets/secureboot_key \
               --cert /run/secrets/secureboot_cert \
               "$kernel" --output "$kernel"; \
    done && \
    # C) PODPIS JADERNÝCH MODULŮ (Nvidia + MSI-EC)
    # Najde všechny .ko (.ko.xz) soubory vygenerované akmods a podepíše je kmitajícím skriptem jádra
    for mod in $(find /lib/modules/ -name "*.ko" -o -name "*.ko.xz"); do \
        /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 \
        /run/secrets/secureboot_key \
        /run/secrets/secureboot_cert \
        "$mod"; \
    done
