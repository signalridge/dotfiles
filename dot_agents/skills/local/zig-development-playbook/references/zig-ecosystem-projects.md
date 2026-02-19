# Zig Ecosystem Projects

Survey date: 2026-02-19.

## Representative Projects

1. Ghostty

- Repo: https://github.com/ghostty-org/ghostty
- GitHub API reports primary language as Zig.
- README states there is a large shared core written in Zig.

2. Bun

- Repo: https://github.com/oven-sh/bun
- README explicitly states the Bun runtime is written in Zig.

3. TigerBeetle

- Repo: https://github.com/tigerbeetle/tigerbeetle
- GitHub API reports primary language as Zig.

4. river

- Repo: https://github.com/riverwm/river
- GitHub API reports primary language as Zig.

5. ZLS (Zig Language Server)

- Repo: https://github.com/zigtools/zls
- GitHub API reports primary language as Zig.

## Usage Guidance

- Use `Ghostty` and `Bun` as high-visibility product examples.
- Use `TigerBeetle` for database/systems performance discussions.
- Use `river` for Linux/Wayland UI systems examples.
- Use `zls` for tooling and editor ecosystem examples.

## Refresh Command

```bash
for r in ghostty-org/ghostty oven-sh/bun tigerbeetle/tigerbeetle riverwm/river zigtools/zls; do
  echo "== $r =="
  curl -sSL "https://api.github.com/repos/$r" | rg '"full_name"|"description"|"language"|"html_url"'
  echo
done
```
