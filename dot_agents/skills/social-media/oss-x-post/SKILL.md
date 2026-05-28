---
name: oss-launch
description: Turn one open-source release/topic into platform-tailored posts and publish them through a gated, auditable path. Use when the user wants to announce or promote an OSS project/release across X, Bluesky, Mastodon, LinkedIn, dev.to, Reddit, Hacker News, etc. Triggers: "announce my release", "promote my repo", "post about this project", "oss launch", "Show HN", "发布开源项目", "宣传项目".
---

# OSS Launch

Take **one topic** (a release, a new project, a milestone) and produce **different,
platform-native content for each target**, then publish through the gated
`social-post` wrapper. One idea in, many tailored posts out — never the same blob
copy-pasted everywhere.

## Voice (non-negotiable)

- English, written for **developers**, in the project author's own voice.
- **No hype, no marketing-speak.** State concrete technical value plainly.
- Never invent metrics, stars, benchmarks, users, or endorsements.
- At most 2 hashtags, and only where they're idiomatic (X/Mastodon).

## Workflow

1. **Gather the brief.** Read what's available: `README.md`, `CHANGELOG.md`, the
   GitHub release body, and the repo URL. Ask the user for the one-line angle if
   it isn't obvious (what's new / why it matters). Keep it small — do not scan the
   whole repo.
2. **Pick targets.** Confirm which platforms to publish to (default offer: X,
   Bluesky, Mastodon, Reddit; add LinkedIn / dev.to when relevant).
3. **Draft per platform.** Write one file per target under `tmp/launch/<platform>.md`
   following the rules below. Each draft is genuinely rewritten for its platform —
   not a truncation of the X post.
4. **Review gate.** Show every draft to the user together. Let them edit. Do not
   proceed until they explicitly approve.
5. **Publish — only through this skill's `scripts/social-post`.** For each approved
   draft run the dry-run first, show it, then re-run with `--yes` after confirmation.
   Never call `crosspost`, `xurl post`, or any platform CLI directly.
6. **Report.** List what was posted (and any failures) with links/IDs.

## Per-platform rules

| Platform | File                         | Limit      | Shape                                                                                                                                   |
| -------- | ---------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| X        | `tmp/launch/x.md`            | 280        | One hook line + concrete value + repo link. ≤2 hashtags.                                                                                |
| Bluesky  | `tmp/launch/bluesky.md`      | 300        | Slightly more relaxed than X; can add one line of context.                                                                              |
| Mastodon | `tmp/launch/mastodon.md`     | 500        | Community tone; add a CW line only if warranted.                                                                                        |
| LinkedIn | `tmp/launch/linkedin.md`     | 3000       | Problem → what you built → who it's for. Professional, still no hype.                                                                   |
| dev.to   | `tmp/launch/devto.md`        | —          | Full technical post (markdown). Lead with the problem; include a code/usage snippet and the canonical repo link.                        |
| Reddit   | `tmp/launch/reddit-<sub>.md` | title ≤300 | Per-subreddit. Frame as "I built X to solve Y, feedback on Z" — not "please star". One file per subreddit, reworded for that community. |

For Reddit, first run the bundled helper `bash "$SKILL/scripts/reddit-submit" rules <sub>`
and `… requirements <sub>` (`$SKILL` defined below) and adapt the draft to that
subreddit's rules before submitting.

## Publishing commands

The publish gate (`social-post`) and the Reddit helper (`reddit-submit`) are bundled in
this skill under `scripts/` — there is no `~/.local/bin` dependency. Dry-run is the
default; `--yes` actually sends. Credentials come from gopass at send time (see
`docs/social-publishing.md`).

```bash
SKILL=~/.agents/skills/social-media/oss-x-post   # this skill's installed path

bash "$SKILL/scripts/social-post" x        --file tmp/launch/x.md
bash "$SKILL/scripts/social-post" bluesky  --file tmp/launch/bluesky.md
bash "$SKILL/scripts/social-post" mastodon --file tmp/launch/mastodon.md
bash "$SKILL/scripts/social-post" linkedin --file tmp/launch/linkedin.md
bash "$SKILL/scripts/social-post" devto    --file tmp/launch/devto.md
bash "$SKILL/scripts/social-post" reddit   --subreddit rust --title "<title>" --file tmp/launch/reddit-rust.md
# add --yes to each, only after the user approves the dry-run
```

## Prepare-only platforms (no API — never auto-post)

These have no publishing API, or automated posting violates their norms and gets
flagged. Produce a ready-to-paste artifact and a checklist, then **open the page so
the user submits manually**. Do not script the submission.

- **Hacker News (Show HN):** title `Show HN: <name> – <one line>` + a first comment
  with the backstory and a direct, signup-free try link. Open <https://news.ycombinator.com/submit>.
- **Lobsters:** only if the user has an account/invite; high-quality writeup. Manual.
- **Product Hunt:** draft the tagline, description, first maker comment, and a media
  checklist. Launch is manual in the PH UI.
- **Directories** (OpenSourceAlternative.to, AlternativeTo, LibHunt, awesome lists):
  for awesome lists, draft a `gh` pull request; for the rest, fill the submit form
  manually.

Write these drafts to `tmp/launch/<platform>.md` too, clearly marked as manual.

## Safety rules (enforced by `social-post`, restated here)

1. Posting only — never reply, DM, follow, like, repost, or chase trends.
2. One main post per platform per launch (an optional thread is fine).
3. Different content per platform; never blast identical text everywhere.
4. Every draft is human-approved before `--yes`.
5. On send failure, stop and report — do not retry in a loop.
