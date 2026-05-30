---
name: remotion
description: Build, run, and render videos programmatically with Remotion (React-based video). Use when scaffolding a Remotion project, writing compositions/animations, previewing in Remotion Studio, rendering to MP4/WebM/GIF/stills, embedding <Player>, or troubleshooting Remotion + Bun. Triggers - "Remotion", "create-video", "remotion studio", "remotion render", "programmatic video", "React video", "做视频", "程序化视频", "用 React 生成视频", "渲染 mp4".
---

# Remotion

Make videos with React: components are frames, `useCurrentFrame()` drives animation,
the CLI renders to MP4/WebM/GIF/image sequences. Great for data-viz videos, batch
personalized videos, audiograms/subtitles, and programmatic intros.

## Before doing anything — house rules

1. **License (ask, don't assume).** Remotion is free for individuals and orgs with
   **≤ 3 people** (commercial use included). A **Company License** ($25/seat/mo+) is
   required for for-profit orgs larger than that. This machine's dotfiles live under
   the `signalridge` org — if a Remotion project is for company work, confirm licensing
   before shipping. Docs: https://www.remotion.dev/docs/license
2. **Never scaffold inside a dotfiles / config repo.** Remotion pulls a large
   `node_modules`, a `package.json`, and video output artifacts. Create projects in a
   dedicated dir (e.g. `~/dev/<name>`), never in `~/.local/share/chezmoi` or `~/.agents`.
3. **Runtime is already set up here:** `bun` ≥ 1.0.3 and `node` ≥ 16 are present.
   FFmpeg is **bundled since Remotion v4** — do not install it separately.

## Scaffold a new project

```bash
bunx create-video@latest        # interactive template picker
```

Templates: Hello World, Blank, TikTok, Audiogram, React Three Fiber, Stills, etc.
The generated `package.json` scripts use `bunx remotionb` (Bun runtime). To use the
Node runtime instead, change `remotionb` → `remotion` in those scripts.

## Add to an existing React project (brownfield)

```bash
bun add remotion @remotion/cli   # plus react + react-dom if missing
```

Register compositions in a `Root.tsx` via `registerRoot()`; point the CLI/Studio at
your entry file (default `src/index.ts`).

## Core commands

```bash
bunx remotion studio                 # live preview/editor (was `remotion preview`)
bunx remotion render <id> [out.mp4]   # render a composition by id
bunx remotion still <id> out.png      # render a single frame
bunx remotion compositions            # list composition ids
```

- Output codec follows the extension (`.mp4` h264, `.webm` vp8/9, `.gif`).
- Cloud/parallel rendering is a separate package: `@remotion/lambda`.
- Embed a player in a normal React app with `<Player>` from `@remotion/player`.

## Bun caveats (this machine defaults to Bun)

Bun support is mostly there (≥ 1.0.3), but with known limits:

- `lazyComponent` on `<Composition>`/`<Player>` is **auto-disabled** under Bun.
- A server-side rendering script **may not quit automatically** when done — call
  `process.exit()` or run that script with `remotion` (Node) instead of `remotionb`.

If either bites, switch the affected script from `remotionb` to `remotion`.

## Composition essentials (when writing code)

- `useCurrentFrame()` → current frame; `useVideoConfig()` → `{ fps, width, height, durationInFrames }`.
- `interpolate(frame, [0, 30], [0, 1], { extrapolateRight: 'clamp' })` for value ramps.
- `spring({ frame, fps })` for natural motion.
- `<Sequence from={..} durationInFrames={..}>` / `<Series>` for timeline composition; `<AbsoluteFill>` for layered layout.
- Static assets go in `public/` and are referenced with `staticFile('name.png')`.
- Time is **frames**, not seconds: `seconds * fps`. Define duration via `durationInFrames` on the `<Composition>`.

## Docs routing (this repo's MCP setup)

- Up-to-date API/snippets → **context7** (resolve `remotion`, then query).
- Repo/architecture questions → **deepwiki** (`remotion-dev/remotion`) or **gitmcp**.
- The official `@remotion/mcp` docs server is **not installed** here by choice; rely on
  context7/deepwiki instead. (If deeper doc grounding is ever wanted, it can be added
  to `.chezmoiscripts/run_after_11_sync-claude-mcp.sh.tmpl` as `bunx @remotion/mcp@latest`.)

## Reproducibility note

For a real project, pin the toolchain the repo way: an `mise.toml` (node/bun) in the
project root keeps renders deterministic across machines and CI.
