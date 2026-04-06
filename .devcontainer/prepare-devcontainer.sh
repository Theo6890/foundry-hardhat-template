#!/usr/bin/env sh

set -eu

usage() {
    echo "Usage: $0 <mounted|unmounted> [--skip-build] [--sync-workspace]" >&2
    exit 1
}

[ "$#" -ge 1 ] || usage

container_type="$1"
shift

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
devcontainer_dir="$workspace_root/.devcontainer/$container_type"
env_file="$devcontainer_dir/.env"
container_name="vsc-$container_type-$repo_name"
container_workspace_folder="/workspaces/$repo_name"
git_user_name=$(git config --global --get user.name 2>/dev/null || true)
git_user_email=$(git config --global --get user.email 2>/dev/null || true)

escape_compose_env() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Prevent macOS from materializing AppleDouble metadata files during workspace syncs.
export COPYFILE_DISABLE=1
export COPY_EXTENDED_ATTRIBUTES_DISABLE=1

case "$container_type" in
    mounted|unmounted)
        ;;
    *)
        usage
        ;;
esac

cat > "$env_file" <<EOF
DEVCONTAINER_NAME=$container_name
DEVCONTAINER_IMAGE=$container_name
LOCAL_WORKSPACE_FOLDER=$workspace_root
CONTAINER_WORKSPACE_FOLDER=$container_workspace_folder
WORKSPACE_VOLUME=$container_name
DEVCONTAINER_GIT_USER_NAME="$(escape_compose_env "$git_user_name")"
DEVCONTAINER_GIT_USER_EMAIL="$(escape_compose_env "$git_user_email")"
EOF

if [ "$skip_build" != "true" ]; then
    docker build -t "$container_name" -f "$devcontainer_dir/Dockerfile" "$workspace_root"
fi

if [ "$sync_workspace" = "true" ]; then
    docker volume create "$container_name" >/dev/null

    tar \
        --exclude='.DS_Store' \
        --exclude='._*' \
        -C "$workspace_root" \
        -cf - . | docker run --rm -i \
        -v "$container_name:/workspace" \
        alpine:3.20 \
        sh -lc 'rm -rf /workspace/* /workspace/.[!.]* /workspace/..?* && tar -xf - -C /workspace && find /workspace -name "._*" -type f -delete && chown -R 1000:1000 /workspace'
fi