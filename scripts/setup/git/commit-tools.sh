#!/usr/bin/env sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/../lib/workspace.sh"

workspace_root=$(resolve_workspace_root "$0" 3)
install_dir="$workspace_root/.git-tools/commitlint"

mkdir -p "$install_dir"

cat > "$install_dir/package.json" <<'EOF'
{
    "packageManager": "yarn@1.22.22",
    "devDependencies": {
        "@commitlint/cli": "^19.8.0",
        "@commitlint/config-conventional": "^19.8.0"
    }
}
EOF

(
    cd "$install_dir"
    pmg yarn install
)

ensure_husky_hooks "$workspace_root"