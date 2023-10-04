FROM fedora:latest AS base

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
RUN dnf install -y procps-ng iputils 'dnf-command(copr)' git

RUN grep -v nodocs /etc/dnf/dnf.conf | tee /etc/dnf/dnf.conf

ARG WSL_GITS_DIR="${WSL_GITS_DIR:-/home/"${WSL_USERNAME}"/gits}"
RUN mkdir -p ${WSL_GITS_DIR} /home/${WSL_USERNAME}/.config
RUN chown -R ${WSL_USERNAME}:${WSL_USERNAME} ${WSL_GITS_DIR} /home/${WSL_USERNAME}/.config
RUN git clone  --recurse-submodules https://github.com/ImperatorMarsa/dotfiles.git ${WSL_GITS_DIR}/dotfiles
RUN ln -s ${WSL_GITS_DIR}/dotfiles/fastfetch /home/${WSL_USERNAME}/.config/fastfetch && \
    ln -s ${WSL_GITS_DIR}/dotfiles/fish      /home/${WSL_USERNAME}/.config/fish      && \
    ln -s ${WSL_GITS_DIR}/dotfiles/nvim      /home/${WSL_USERNAME}/.config/nvim      && \
    ln -s ${WSL_GITS_DIR}/dotfiles/lsd       /home/${WSL_USERNAME}/.config/lsd

RUN dnf copr -y enable atim/starship && \
    dnf copr -y enable atim/lazygit  && \
    dnf copr -y enable atim/zoxide
RUN dnf install -y \
    cbonsai \
    fastfetch \
    fish \
    fzf \
    lazygit \
    neovim \
    podman \
    ripgrep \
    starship \
    tmux \
    vim \
    zoxide \
    util-linux-user

FROM rust:latest AS lsd_builder
RUN apt-get update && apt-get install -y git
RUN cargo install --git https://github.com/lsd-rs/lsd.git --branch master
FROM base
COPY --from=lsd_builder /usr/local/cargo/bin/lsd /usr/bin/lsd

FROM fedora:latest AS fastfetch_builder
RUN dnf -y update
RUN dnf install -y git cmake pkgconf-pkg-config
RUN dnf group install -y "C Development Tools and Libraries" "Development Tools"
WORKDIR /tmp
RUN git clone -b master https://github.com/fastfetch-cli/fastfetch.git && \
    cd fastfetch && \
    mkdir -p build && \
    cd build && \
    cmake .. && \
    cmake --build . --target fastfetch --target flashfetch
FROM base
COPY --from=fastfetch_builder /tmp/fastfetch/build/fastfetch /usr/bin/fastfetch

RUN chsh -s /usr/bin/fish ${WSL_USERNAME}

RUN dnf clean all
