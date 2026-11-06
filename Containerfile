FROM quay.io/fedora/fedora-bootc:45

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
        nano \
        tmux \
        xorg-x11-drv-nvidia-cuda \
    && dnf5 clean all \
    && rm -rf /var/cache/dnf

# Build modules for every kernel shipped in the image. Secure Boot signing is
# performed on the target using its enrolled MOK key.
RUN for kernel in /usr/lib/modules/*; do \
        [ -d "$kernel" ] || continue; \
        kver="${kernel##*/}"; \
        akmods --force --kernels "$kver"; \
    done \
    && depmod -a

RUN flatpak remote-add --if-not-exists \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
    && flatpak install --system --assumeyes flathub org.mozilla.firefox \
    && flatpak repair --system \
    && rm -rf /var/tmp/* /var/cache/*
