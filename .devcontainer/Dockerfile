# Base Alpine build.
FROM mcr.microsoft.com/vscode/devcontainers/base:alpine

# Install system packages.
RUN apk add --no-cache \
		bash \
		build-base \
		ca-certificates \
		gcompat \
		libffi-dev \
		libstdc++ \
		openssl-dev \
		curl \
		nodejs \
		npm \
		py3-pip \
		python3 \
		git \
		zsh \
		bash-completion \
	&& npm install -g corepack \
	&& corepack enable \
	&& COREPACK_ENABLE_DOWNLOAD_PROMPT=0 corepack install -g yarn@1.22.22 \
	&& npm install -g @safedep/pmg@0.5.0

# Set the default interactive shell to zsh
ENV SHELL=/bin/zsh

# Dropping privileges
USER vscode

# Install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install uv and add to PATH
# See https://docs.astral.sh/uv/guides/integration/docker/
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
ENV PATH="/home/vscode/.local/bin:/home/vscode/.cargo/bin:/home/vscode/.foundry/bin:/home/vscode/.cyfrin/bin:$PATH"

# Add shell aliases
RUN echo 'alias c="clear"' >> ~/.zshrc
RUN echo 'alias C="clear"' >> ~/.zshrc

# Install tools using uv
RUN uv tool install solc-select
RUN uv tool install slither-analyzer
RUN uv tool install crytic-compile

# Preinstall the repo's required solc version and point Foundry at the local binary.
RUN solc-select install 0.8.34 && solc-select use 0.8.34
ENV FOUNDRY_SOLC="/home/vscode/.local/bin/solc"

# Foundry framework
RUN curl -L https://foundry.paradigm.xyz | bash
RUN foundryup --platform alpine

# Aderyn
RUN curl -L https://raw.githubusercontent.com/Cyfrin/up/main/install | bash
RUN cyfrinup