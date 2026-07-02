#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "required command not found: $1" >&2
        exit 1
    }
}

for c in bash chezmoi git shellcheck treefmt; do
    require_cmd "$c"
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/check-templates.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

RENDER_ROOT="$TMP_ROOT/rendered"
mkdir -p "$RENDER_ROOT"

for cfg in treefmt.toml stylua.toml selene.toml; do
    if [[ -f "$ROOT/$cfg" ]]; then
        cp "$ROOT/$cfg" "$RENDER_ROOT/"
    fi
done

cat >"$TMP_ROOT/chezmoi.toml" <<'EOF'
[data]
hostname = "test"
work = false
private = true
homeWifiSSIDs = ""
platform = "darwin"
installMasApps = true
timezone = "UTC"
gitUsername = "test"
gitEmail = "test@test.com"
useremail = "test@test.com"
useEncryption = false
headless = false
gopassRepository = "https://github.com/test/pass.git"
keysRepository = "https://github.com/test/keys.git"
codexProviderAccount = "openai"
claudeProviderAccount = "anthropic"
EOF

render_error_log="$TMP_ROOT/chezmoi-render.stderr"
: >"$render_error_log"
render_failed_files=()

render_template() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname -- "$dest")"
    if [[ "$src" == ".chezmoi.toml.tmpl" ]]; then
        if ! chezmoi execute-template --config "$TMP_ROOT/chezmoi.toml" --init --stdinisatty=false --source "$ROOT" <"$ROOT/$src" >"$dest" 2>>"$render_error_log"; then
            echo "template render failed: $src" >&2
            render_failed_files+=("$src")
            return 1
        fi
        return 0
    fi

    if ! chezmoi execute-template --config "$TMP_ROOT/chezmoi.toml" --source "$ROOT" <"$ROOT/$src" >"$dest" 2>>"$render_error_log"; then
        echo "template render failed: $src" >&2
        render_failed_files+=("$src")
        return 1
    fi
}

while IFS= read -r -d "" template_path; do
    case "$template_path" in
    */Spoons/* | node_modules/*)
        continue
        ;;
    esac
    render_template "$template_path" "$RENDER_ROOT/${template_path%.tmpl}" || true
done < <(
    git -C "$ROOT" ls-files -z --cached --others --exclude-standard '*.tmpl' |
        while IFS= read -r -d "" template_path; do
            [[ -f "$ROOT/$template_path" ]] && printf '%s\0' "$template_path"
        done
)

if ((${#render_failed_files[@]} > 0)); then
    echo "" >&2
    echo "template rendering failed for ${#render_failed_files[@]} file(s):" >&2
    for f in "${render_failed_files[@]}"; do
        echo "  - $f" >&2
    done
    echo "" >&2
    echo "---- chezmoi stderr (last 200 lines) ----" >&2
    tail -200 "$render_error_log" >&2 || true
    exit 1
fi

cd "$RENDER_ROOT"

echo "Checking rendered templates with treefmt..."
treefmt --fail-on-change

is_shell_script() {
    local file="$1"
    local first_line

    case "$file" in
    *.sh | *.bash)
        return 0
        ;;
    esac

    first_line="$(head -n 1 "$file" 2>/dev/null || true)"
    [[ "$first_line" =~ ^#!.*(bash|sh)([[:space:]]|$) ]]
}

shellfiles=()
while IFS= read -r -d "" file; do
    if is_shell_script "$file"; then
        shellfiles+=("$file")
    fi
done < <(find . -type f -print0)

if ((${#shellfiles[@]} > 0)); then
    echo "Linting rendered shell scripts..."
    shellcheck --severity=warning --exclude=SC2034 "${shellfiles[@]}"
fi

luafiles=()
while IFS= read -r -d "" file; do
    luafiles+=("$file")
done < <(find . -type f -name '*.lua' ! -path '*/Spoons/*' -print0)

if ((${#luafiles[@]} > 0)) && [[ -f selene.toml ]]; then
    echo "Linting rendered Lua files..."
    if command -v selene >/dev/null 2>&1; then
        selene "${luafiles[@]}" || echo "Selene warnings (non-blocking)"
    else
        echo "Selene not found; skipping Lua lint"
    fi
fi

nixfiles=()
while IFS= read -r -d "" file; do
    nixfiles+=("$file")
done < <(find . -type f -name '*.nix' -print0)

if ((${#nixfiles[@]} > 0)); then
    echo "Linting rendered Nix files..."
    if command -v statix >/dev/null 2>&1; then
        statix check . || echo "Statix warnings (non-blocking)"
    else
        echo "Statix not found; skipping Nix lint"
    fi
fi

echo "All rendered template checks passed."
