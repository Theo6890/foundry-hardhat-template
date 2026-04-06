#!/usr/bin/env sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
workspace_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

if ! command -v git >/dev/null 2>&1; then
    exit 0
fi

if [ -n "${DEVCONTAINER_GIT_USER_NAME:-}" ]; then
    git config --global --replace-all user.name "$DEVCONTAINER_GIT_USER_NAME"
else
    git config --global --unset-all user.name >/dev/null 2>&1 || true
fi

if [ -n "${DEVCONTAINER_GIT_USER_EMAIL:-}" ]; then
    git config --global --replace-all user.email "$DEVCONTAINER_GIT_USER_EMAIL"
else
    git config --global --unset-all user.email >/dev/null 2>&1 || true
fi

printf 'Global git user.name: %s\n' "$(git config --global --get user.name || printf '<not set>')"
printf 'Global git user.email: %s\n' "$(git config --global --get user.email || printf '<not set>')"

cd "$workspace_root"

yarn install
forge soldeer install
forge b
