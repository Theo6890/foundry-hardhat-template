#!/usr/bin/env sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/../lib/workspace.sh"

workspace_root=$(resolve_workspace_root "$0" 3)
bootstrap_state_file="$workspace_root/.devcontainer/.bootstrap-state"

configure_writable_runtime_environment() {
    if [ -z "${HOME:-}" ] || [ ! -d "$HOME" ] || [ ! -w "$HOME" ]; then
        export HOME=/tmp/devcontainer-home
    fi

    export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-/tmp/devcontainer-config}
    export XDG_CACHE_HOME=${XDG_CACHE_HOME:-/tmp/devcontainer-cache}
    export XDG_STATE_HOME=${XDG_STATE_HOME:-/tmp/devcontainer-state}
    export COREPACK_HOME=${COREPACK_HOME:-$XDG_CACHE_HOME/corepack}
    export npm_config_cache=${npm_config_cache:-$XDG_CACHE_HOME/npm}
    export YARN_CACHE_FOLDER=${YARN_CACHE_FOLDER:-$XDG_CACHE_HOME/yarn}
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=${COREPACK_ENABLE_DOWNLOAD_PROMPT:-0}

    mkdir -p \
        "$HOME" \
        "$XDG_CONFIG_HOME" \
        "$XDG_CACHE_HOME" \
        "$XDG_STATE_HOME" \
        "$COREPACK_HOME" \
        "$npm_config_cache" \
        "$YARN_CACHE_FOLDER"
}

ensure_tool_paths() {
    export PATH="/home/vscode/.local/bin:/home/vscode/.cargo/bin:/home/vscode/.foundry/bin:/home/vscode/.cyfrin/bin:$PATH"
}

configure_writable_git_global_config() {
    config_home=${XDG_CONFIG_HOME:-$HOME/.config}

    if [ ! -d "$config_home" ] || [ ! -w "$config_home" ]; then
        config_home=/tmp/devcontainer-config
    fi

    git_config_dir="$config_home/git"
    git_config_path="$git_config_dir/config"

    mkdir -p "$git_config_dir"
    : > "$git_config_path"
    export GIT_CONFIG_GLOBAL="$git_config_path"
}

set_global_git_identity() {
    key=$1
    value=$2

    if [ -n "$value" ]; then
        git config --global --replace-all "$key" "$value"
    else
        git config --global --unset-all "$key" >/dev/null 2>&1 || true
    fi
}

sync_global_git_identity() {
    if ! command -v git >/dev/null 2>&1; then
        return 0
    fi

    set_global_git_identity user.name "${DEVCONTAINER_GIT_USER_NAME:-}"
    set_global_git_identity user.email "${DEVCONTAINER_GIT_USER_EMAIL:-}"

    printf 'Global git user.name: %s\n' "$(git config --global --get user.name || printf '<not set>')"
    printf 'Global git user.email: %s\n' "$(git config --global --get user.email || printf '<not set>')"
}

manifest_fingerprint() {
    (
        cd "$workspace_root"
        cksum package.json yarn.lock 2>/dev/null | awk '{print $1":"$2":"$3}' | tr '\n' '|'
    )
}

should_run_yarn_install() {
    [ ! -d "$workspace_root/node_modules" ] && return 0
    [ ! -f "$bootstrap_state_file" ] && return 0

    current_fingerprint=$(manifest_fingerprint)
    saved_fingerprint=$(cat "$bootstrap_state_file" 2>/dev/null || true)
    [ "$current_fingerprint" != "$saved_fingerprint" ]
}

write_bootstrap_state() {
    manifest_fingerprint > "$bootstrap_state_file"
}

ensure_foundry_solc() {
    if [ -z "${FOUNDRY_SOLC:-}" ] && command -v solc >/dev/null 2>&1; then
        export FOUNDRY_SOLC=$(command -v solc)
    fi
}

install_workspace_dependencies() {
    if should_run_yarn_install; then
        (
            cd "$workspace_root"
            pmg yarn install --frozen-lockfile
        )
        write_bootstrap_state
    else
        printf 'Skipping yarn install; dependency manifests unchanged.\n'
    fi

    ensure_husky_hooks "$workspace_root"

    if [ ! -d "$workspace_root/dependencies" ]; then
        (
            cd "$workspace_root"
            forge soldeer install
        )
    else
        printf 'Skipping forge soldeer install; dependencies already present.\n'
    fi

    if [ ! -d "$workspace_root/out" ]; then
        (
            cd "$workspace_root"
            forge b
        )
    else
        printf 'Skipping forge build; build artifacts already present.\n'
    fi
}

main() {
    configure_writable_runtime_environment
    ensure_tool_paths
    configure_writable_git_global_config
    sync_global_git_identity
    ensure_foundry_solc
    install_workspace_dependencies
}

main "$@"