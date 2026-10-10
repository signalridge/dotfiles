#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v chezmoi >/dev/null 2>&1 || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/pi-mcp-config-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

for name in mcp mcp-adapter; do
    chezmoi execute-template --source "$ROOT" \
        <"$ROOT/dot_pi/agent/$name.json.tmpl" >"$TMP_ROOT/$name.json"
done

python3 - "$TMP_ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
standard = json.loads((root / "mcp.json").read_text())
adapter = json.loads((root / "mcp-adapter.json").read_text())
expected = {
    "context7": {"url": "https://mcp.context7.com/mcp"},
    "deepwiki": {"url": "https://mcp.deepwiki.com/mcp"},
    "gitmcp": {"url": "https://gitmcp.io/docs"},
    "markitdown": {"command": "uvx", "args": ["markitdown-mcp"]},
    "arxiv": {"command": "uv", "args": ["tool", "run", "arxiv-mcp-server"]},
}

# Pi's native config must not carry ignored adapter settings or lose transports.
assert standard == {"mcpServers": expected}, standard
assert adapter["settings"] == {"showStatusIcon": False}, adapter
assert set(adapter["mcpServers"]) == set(expected), adapter
for name, transport in expected.items():
    override = adapter["mcpServers"][name]
    wanted = {"lifecycle": "lazy"}
    if "url" in transport:
        wanted["directTools"] = True
    assert override == wanted, (name, override)
    # The adapter's field-wise merge must preserve the single transport source.
    assert {**transport, **override} == {**transport, **wanted}
PY

echo "test_pi_mcp_config: OK"
