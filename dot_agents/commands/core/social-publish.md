# /social-publish - Launch an OSS topic across platforms

Explicit entry point for turning one topic/release into platform-tailored posts and
publishing them through the gated `social-post` wrapper.

## When to Use

- Announcing a release or new open-source project to a developer audience
- You want one topic adapted into different per-platform content (not copy-paste)
- You want a human-approved, auditable publish — no browser automation, no bare CLI

## Workflow

Run the **`oss-launch`** skill (`~/.agents/skills/social-media/oss-x-post/`). It:

1. Gathers the brief (README / CHANGELOG / release body / repo URL + a one-line angle).
2. Confirms target platforms.
3. Drafts one platform-native file per target under `tmp/launch/<platform>.md`
   (no-hype, dev-audience, English).
4. Shows all drafts for review — waits for explicit approval.
5. Publishes each via `social-post <platform> --file … --yes` (dry-run first, then
   `--yes` after confirmation). For Reddit it goes through `reddit-submit`.
6. For no-API platforms (Show HN, Lobsters, Product Hunt, directories) it prepares a
   ready-to-paste artifact + checklist and opens the page — it never auto-posts.

## Rules

- Publishing happens **only** through `social-post`; never call `crosspost`,
  `xurl post`, or any platform CLI directly.
- Every draft is human-approved before `--yes`.
- Credentials are read from gopass at send time — see `docs/social-publishing.md`.
