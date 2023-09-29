FROM fedora:latest

ARG WSL_USERNAME="${WSL_USERNAME:-username}"
ARG WSL_PASSWORD="${WSL_PASSWORD:-password}"

RUN dnf -y update
RUN dnf install -y \
    util-linux \
    passwd \
    cracklib-dicts \
    iproute \
    findutils \
    ncurses \
    man \
    man-pages

RUN useradd -G wheel "${WSL_USERNAME}"
RUN echo -e ""${WSL_PASSWORD}"\n"${WSL_PASSWORD}"" | passwd "${WSL_USERNAME}"
RUN printf "\n[user]\ndefault = "${WSL_USERNAME}"\n" | sudo tee -a /etc/wsl.conf
RUN dnf reinstall -y shadow-utils
RUN dnf install -y procps-ng iputils

RUN grep -v nodocs /etc/dnf/dnf.conf | tee /etc/dnf/dnf.conf

RUN dnf clean all
