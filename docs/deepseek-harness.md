# DeepSeek Harness

Official project: <https://github.com/deepseek-ai/deepseek-harness>.
Developer preview; expect breaking changes. Read upstream `SAFETY.md` before
using it on a real project. Keep its default approval controls; prefer a scratch
workspace for the first trial.

## Installation and launch

`private_dot_config/mise/config.toml.tmpl` installs `@deepseek-ai/dsh` at the
explicitly tested version `0.2.0-rc.2`, through the existing mise/Bun backend.
Upgrade that pin deliberately, then retest Web startup and native subprocesses.

```sh
# Normal chezmoi apply installs it through script 07. Targeted installation:
chezmoi apply --include files ~/.config/mise/config.toml ~/.local/bin/dsh-with ~/.dsh/cordis.patch.yml
mise install --yes npm:@deepseek-ai/dsh@0.2.0-rc.2
mise reshim

cd /path/to/scratch-project
dsh-with                     # defaults to web; opens http://127.0.0.1:3080
# or: dsh-with web --no-open
# or: dsh-with headless "只回复 OK，不要调用工具"
```

The Web UI starts without a selected workspace; choose the scratch directory
before sending a message. Stop the server with Ctrl-C. No background service is
installed. The raw `dsh` command requires a profile (`dsh web`, not just `dsh`)
and does not load the proxy key automatically. `dsh-with` uses `mise exec`, so
it also works in a shell whose tool PATH predates the installation.

## Default model: OpenAI OAuth via CLIProxyAPI

The `cliproxy` provider uses **OpenAI Responses**, not Anthropic Messages:
`http://127.0.0.1:8317/v1/responses`, with `gpt-6.1-sol` and high reasoning.
CLIProxyAPI owns the existing OpenAI/Codex OAuth login and refreshes it; Harness
uses only the local proxy's inbound client key. This is OAuth-backed inference
through a gateway, not a separate OAuth login inside Harness.

The proxy must be running and its OAuth account must be valid. No DeepSeek API
key or paid OpenAI API key is needed for this default route. Subscription limits
and upstream model availability still apply.

`dsh-with` reads `claude/cliproxy/private/api_key` from gopass on launch and
passes it only in the child process environment as `CLIPROXY_API_KEY`. The
`claude/` prefix is the existing shared secret's storage location, **not the
wire protocol**. It never writes keys or OAuth tokens to the source tree or a
dsh credentials file. An existing `CLIPROXY_API_KEY` takes precedence; use
`DSH_GOPASS_PATH` to choose another proxy secret. Help/version/config dumps do
not unlock gopass. Never enable shell tracing around real credentials.

## Proxy setup and operation

CLIProxyAPI is pinned through the existing aqua toolchain, with official release
checksums. Its config and macOS LaunchAgent render only when encryption is
enabled and the existing gopass key is present. A missing/unreadable key fails
closed; a machine with no key skips these files.

```sh
# On a new machine only: create the inbound client key, then apply chezmoi.
openssl rand -hex 32 | gopass insert -f -m claude/cliproxy/private/api_key
chezmoi apply

# Complete OpenAI/Codex OAuth login (callback port 1455).
cliproxyapi --config "$HOME/.cli-proxy-api/config.yaml" --codex-login

# macOS service status
launchctl print gui/$(id -u)/com.signalridge.cliproxyapi
```

OAuth credentials rotate under `~/.cli-proxy-api/`, outside the repository and
gopass. If the key was restored by the same apply, apply again to render the
proxy files. Stop a manually started proxy before loading the LaunchAgent to
avoid a port conflict. The service runs as the logged-in user, binds only
`127.0.0.1:8317`, and disables the management API.

Claude Code no longer has a CPA account or provider. The proxy does **not**
rewrite `xhigh` to `high`; Harness's `high` reasoning is its own default, not a
proxy conversion rule.

CLIProxyAPI uses the ChatGPT Codex backend rather than the public Platform API.
Check upstream terms and account eligibility; a proxy grants no extra entitlement.

## Privacy and ownership

`~/.dsh/cordis.patch.yml` owns the proxy provider and new-session defaults, and
disables the additional DeepSeek session-log contribution and feedback/OTel
uploads for every profile. Model requests still send the prompt and context
needed for inference to the selected provider. Existing sessions retain their
recorded model; start a new session to use the new default.

Workspaces, sessions, profile settings, and any UI-saved credentials remain
owned by dsh, not chezmoi. Home-level managed overrides take precedence over
Web UI settings. Other providers can be added to the managed `llm-pi-ai`
provider dictionary; a Cordis config override replaces that complete dictionary.
