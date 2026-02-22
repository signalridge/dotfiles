## 1. Shared command source

- [x] 1.1 Add shared command templates under `dot_agents/commands/core` for plan, review, commit, context, test, pr-review, pr-create
- [x] 1.2 Convert `dot_claude/commands/core/*.md` into symlinks to the shared command templates

## 2. Codex prompts

- [x] 2.1 Add `dot_codex/prompts/*.md` symlink templates for each shared command
- [x] 2.2 Ensure Codex prompt filenames align with slash commands (top-level, no subdirs)

## 3. Codex config enhancements

- [x] 3.1 Extend `.chezmoidata/codex.yaml` with new feature/tool toggles and web_search mode
- [x] 3.2 Update `dot_codex/config.toml.tmpl` to render expanded features/tools, suppress warnings, and environment policy
- [x] 3.3 Update `dot_codex/AGENTS.md.tmpl` to document shared command location (if needed)

## 4. Verification

- [ ] 4.1 Run `chezmoi diff` to verify rendered prompts and commands
- [x] 4.2 Confirm `~/.codex/prompts/*.md` and `~/.claude/commands/core/*.md` include shared content
