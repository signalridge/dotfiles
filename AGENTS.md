# Project Constitution — chezmoi dotfiles (`~/.local/share/chezmoi`)

These are **inviolable** rules for ANY agent (Claude Code, Codex, pi, etc.) working
in this repository. They **override** default behaviors, convenience, and general
instincts. When anything conflicts with this file, **this file wins**. The same
constitution is mirrored in `CLAUDE.md`; keep the two in sync.

---

## Article 1 — NO git worktrees. Ever. 🚫🌳

- **NEVER** run `git worktree add` in this repo.
- **NEVER** create a `.worktrees/` directory, or place any worktree, **anywhere
  inside the source tree** (`~/.local/share/chezmoi`).
- **Why (do not "optimize" this away):** chezmoi reads **every** `.chezmoidata/`
  directory in the source tree **recursively** — it does not skip dot-dirs, and
  `.chezmoiignore` **cannot** exclude it (the data pass runs earlier and separately).
  An in-source worktree's `.chezmoidata/*.yaml` is merged into global template data
  and **silently clobbers** the main checkout's config on every `chezmoi apply` /
  `chezmoi execute-template` (the alphabetically-last worktree wins). This has
  corrupted `pi`/`claude` config in practice.
- If you find a worktree here, treat it as a **defect**: surface it, then — with all
  commits/branches preserved — remove it (`git worktree remove [--force] <path>`;
  `--force` discards that worktree's _uncommitted_ changes, so check
  `git -C <path> status` first).

## Article 2 — NEVER switch the shared main checkout.

- Do **not** `git switch` / `git checkout -b` on this checkout. chezmoi's **live
  source IS this working tree**; moving `HEAD` yanks files out from under the user
  and breaks their live `dot apply`.
- To make a change: **edit on `main` and commit small**, or work in a **separate
  clone outside** `~/.local/share/chezmoi`. Branch isolation via an in-source
  worktree is forbidden by Article 1.

## Article 3 — Merging & sync.

- Native auto-merge is **disabled**. Squash-merge a PR only when
  `mergeStateStatus=CLEAN`: `gh pr merge <n> --squash --delete-branch`, then
  `git pull --ff-only origin main` to sync the local main checkout (a
  `darwin-rebuild` / `dot apply` from stale local main can reinstall/rewrite things).
