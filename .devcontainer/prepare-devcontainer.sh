#!/usr/bin/env sh

set -eu

usage() {
    echo "Usage: $0 [--skip-build] [--sync-workspace]" >&2
    exit 1
}

skip_build=false
sync_workspace=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --skip-build)
            skip_build=true
            ;;
        --sync-workspace)
            sync_workspace=true
            ;;
        *)
            usage
            ;;
    esac
    shift
done

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
workspace_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
repo_name=$(basename "$workspace_root")
devcontainer_dir="$workspace_root/.devcontainer"
dockerfile_path="$workspace_root/.devcontainer/Dockerfile"
env_file="$devcontainer_dir/.env"
container_name="vsc-$repo_name"
container_workspace_folder="/workspace"
git_user_name=$(git config --global --get user.name 2>/dev/null || true)
git_user_email=$(git config --global --get user.email 2>/dev/null || true)
cache_volume="$container_name-cache"

tmpfs_vscode_server="/home/vscode/.vscode-server:rw,exec,nosuid,size=768m,uid=1000,gid=1000"
tmpfs_vscode_server_insiders="/home/vscode/.vscode-server-insiders:rw,exec,nosuid,size=256m,uid=1000,gid=1000"
tmpfs_cache="/home/vscode/.cache:rw,nosuid,size=256m,uid=1000,gid=1000"
tmpfs_config="/home/vscode/.config:rw,nosuid,size=128m,uid=1000,gid=1000"
tmpfs_tmp="/tmp:rw,exec,nosuid,size=2g"
tmpfs_var_tmp="/var/tmp:rw,exec,nosuid,size=2g"
tmpfs_run="/run:rw,nosuid,size=128m"

resolve_container_cli() {
    if [ -n "${DEVCONTAINER_CONTAINER_CLI:-}" ]; then
        printf '%s\n' "$DEVCONTAINER_CONTAINER_CLI"
        return 0
    fi

    if command -v podman >/dev/null 2>&1; then
        printf '%s\n' "podman"
        return 0
    fi

    if command -v docker >/dev/null 2>&1; then
        printf '%s\n' "docker"
        return 0
    fi

    echo "prepare-devcontainer.sh: neither podman nor docker is installed or available on PATH" >&2
    exit 1
}

container_cli=$(resolve_container_cli)

case "$(basename "$container_cli")" in
    podman)
        tmpfs_vscode_server="/home/vscode/.vscode-server:rw,exec,nosuid,size=512m"
        tmpfs_vscode_server_insiders="/home/vscode/.vscode-server-insiders:rw,exec,nosuid,size=256m"
        tmpfs_cache="/home/vscode/.cache:rw,nosuid,size=256m"
        tmpfs_config="/home/vscode/.config:rw,nosuid,size=128m"
        ;;
esac

escape_compose_env() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Prevent macOS from materializing AppleDouble metadata files during workspace syncs.
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

cat > "$env_file" <<EOF
DEVCONTAINER_NAME=$container_name
DEVCONTAINER_IMAGE=$container_name
LOCAL_WORKSPACE_FOLDER=$workspace_root
CONTAINER_WORKSPACE_FOLDER=$container_workspace_folder
WORKSPACE_VOLUME=$container_name
CACHE_VOLUME=$cache_volume
DEVCONTAINER_GIT_USER_NAME="$(escape_compose_env "$git_user_name")"
DEVCONTAINER_GIT_USER_EMAIL="$(escape_compose_env "$git_user_email")"
TMPFS_VSCODE_SERVER=$tmpfs_vscode_server
TMPFS_VSCODE_SERVER_INSIDERS=$tmpfs_vscode_server_insiders
TMPFS_CACHE=$tmpfs_cache
TMPFS_CONFIG=$tmpfs_config
TMPFS_TMP=$tmpfs_tmp
TMPFS_VAR_TMP=$tmpfs_var_tmp
TMPFS_RUN=$tmpfs_run
EOF

if [ "$skip_build" != "true" ]; then
    "$container_cli" build -t "$container_name" -f "$dockerfile_path" "$workspace_root"
fi

if [ "$sync_workspace" = "true" ]; then
    if ! "$container_cli" volume inspect "$container_name" >/dev/null 2>&1; then
        "$container_cli" volume create "$container_name" >/dev/null
    fi

    tar \
        --exclude='.DS_Store' \
        --exclude='._*' \
        -C "$workspace_root" \
        -cf - . | "$container_cli" run --rm -i \
        -v "$container_name:/workspace" \
        alpine:3.20 \
        sh -lc 'rm -rf /workspace/* /workspace/.[!.]* /workspace/..?* && tar -xf - -C /workspace && find /workspace -name "._*" -type f -delete && chown -R 1000:1000 /workspace'
fi