#!/usr/bin/env sh

resolve_workspace_root() {
    script_path=$1
    parents_up=${2:-1}
    script_dir=$(CDPATH= cd -- "$(dirname "$script_path")" && pwd)
    workspace_root=$script_dir
    depth=0

    while [ "$depth" -lt "$parents_up" ]; do
        workspace_root=$(CDPATH= cd -- "$workspace_root/.." && pwd)
        depth=$((depth + 1))
    done

    printf '%s\n' "$workspace_root"
}

ensure_husky_hooks() {
    workspace_root=$1

    if [ -x "$workspace_root/node_modules/.bin/husky" ] && [ ! -d "$workspace_root/.husky/_" ]; then
        (
            cd "$workspace_root"
            node ./node_modules/husky/bin.js
        )
    fi
}