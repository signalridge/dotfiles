# Social publishing

Publish **one topic as platform-tailored content** to developer platforms, with a
single hard safety gate and no browser automation.

## Layers

```
topic / release
  └─ oss-launch skill        drafts per-platform content -> tmp/launch/<platform>.md
       └─ human review
            └─ social-post   the gate: dry-run by default, --yes to send, length check,
                             post-only, loads secrets from gopass
                 ├─ crosspost -<plat> --file …   (x, bluesky, devto)
                 └─ reddit-submit submit …       (reddit)
  └─ /social-publish         explicit command entry that runs the oss-launch flow
```

- **Auto-publish (API):** X, Bluesky, dev.to, Reddit.
- **Prepare-only (no API / norms forbid auto-posting):** Hacker News (Show HN),
  Lobsters, Product Hunt launch, directories. The skill drafts + opens the page; you
  submit manually.
- **Repo ops:** GitHub via `gh`, GitLab via `glab`.

## Tools

| Tool            | Backend                               | Role                                                 |
| --------------- | ------------------------------------- | ---------------------------------------------------- |
| `social-post`   | `oss-launch` skill `scripts/`         | The gate. `social-post <platform> --file … [--yes]`. |
| `crosspost`     | `npm:@humanwhocodes/crosspost` (mise) | Multi-platform publish engine.                       |
| `reddit-submit` | `oss-launch` skill `scripts/`         | Narrow Reddit OAuth submit helper.                   |

## Credentials (gopass)

Secrets are read from gopass at send time (never stored in the repo). Dry-run does
**not** need credentials, so you can preview without them. Each env var falls back
to gopass at the path below; you may also pre-export the env var.

| Platform | gopass paths                                                                                         | crosspost / helper env                                                                                               |
| -------- | ---------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| X        | `social/twitter/{consumer_key,consumer_secret,access_token_key,access_token_secret}`                 | `TWITTER_API_CONSUMER_KEY`, `TWITTER_API_CONSUMER_SECRET`, `TWITTER_ACCESS_TOKEN_KEY`, `TWITTER_ACCESS_TOKEN_SECRET` |
| Bluesky  | `social/bluesky/{identifier,password}` (optional `host`)                                             | `BLUESKY_IDENTIFIER`, `BLUESKY_PASSWORD`, `BLUESKY_HOST`                                                             |
| dev.to   | `social/devto/api_key`                                                                               | `DEVTO_API_KEY`                                                                                                      |
| Reddit   | `social/reddit/{client_id,refresh_token}` (+ `client_secret` for script apps, optional `user_agent`) | `REDDIT_CLIENT_ID`, `REDDIT_CLIENT_SECRET`, `REDDIT_REFRESH_TOKEN`, `REDDIT_USER_AGENT`                              |

Store a secret, e.g.:

```bash
gopass insert social/bluesky/identifier      # you@example.com
gopass insert social/bluesky/password        # Bluesky app password (not your login)
```

### Token hygiene — static secrets only

`social-post` and the chezmoi templates only **read** gopass; they never write back. So
gopass may hold only **static, long-lived** secrets. Short-lived/rotating tokens are
minted in memory at send time and never stored.

- **Never put a rotating refresh token in gopass.** In particular avoid **X OAuth 2.0**:
  its refresh token is single-use and rotates on every refresh, so a read-only copy goes
  stale after the first use (you'd have to write the new one back and commit/push the
  gopass repo — fragile across machines). Use **X OAuth 1.0a** (static access token +
  secret), which is exactly what crosspost expects.
- Everything in the table above is static: X OAuth 1.0a tokens, the Bluesky app password,
  the dev.to API key, and Reddit's `permanent` refresh token (revoke-only, does not rotate).
- Ephemeral tokens — Reddit's 1-hour access token, the Bluesky session JWT — are derived
  at runtime from the static secret and never touch gopass or any rendered config.

### Getting tokens

- **X:** create an app in the X developer portal, enable OAuth 1.0a user context with
  write, and copy the consumer key/secret + access token key/secret. Set a spending
  limit on the API.
- **Bluesky:** Settings → App Passwords → create one. Use your handle as identifier.
- **dev.to:** Settings → Extensions → DEV API keys → generate.
- **Reddit:** create a "script" app, then bootstrap a permanent refresh token with the
  existing helper:

  ```bash
  SKILL=~/.harnesses/skills/oss-x-post
  bash "$SKILL/scripts/reddit-submit" auth-url --client-id <id>      # open URL, authorize, copy the code
  bash "$SKILL/scripts/reddit-submit" exchange-code --client-id <id> --code <code>
  # The response (incl. refresh_token) is written to a mode-600 tempfile under $TMPDIR
  # and the path is printed on stderr -- tokens are never echoed to stdout / scrollback.
  # Follow the printed instructions to pipe the refresh_token into gopass and `rm` the file.
  ```

  Token hygiene: never `cat` the file, never paste it into chat, and `rm` it as soon as
  the refresh_token is in gopass. Reddit's `permanent` refresh token does not rotate, so
  if it ever leaks you must revoke the app in the Reddit developer console -- rotating
  the client secret alone is not sufficient.

## Usage

```bash
SKILL=~/.harnesses/skills/oss-x-post

# preview (dry-run, no credentials needed)
bash "$SKILL/scripts/social-post" bluesky --file tmp/launch/bluesky.md

# publish after review
bash "$SKILL/scripts/social-post" bluesky --file tmp/launch/bluesky.md --yes
bash "$SKILL/scripts/social-post" reddit  --subreddit rust --title "<title>" --file tmp/launch/reddit-rust.md --yes
```

Or drive the whole flow with the `oss-launch` skill / `/social-publish` command, which
drafts every platform from one topic, waits for your approval, then sends through
`social-post`.

## Safety

`social-post` enforces: dry-run by default, length limits per platform, post-only (no
reply/DM/follow/like/repost), and a single send attempt (no retry loops). One topic is
rewritten per platform — identical text is never blasted everywhere. These mirror the
X automation rules and avoid spam/bot flags.

Length checks use `wc -m` (code-point count), which is a _necessary but not sufficient_
proxy. X's server-side counter weighs most emojis as 2 and normalizes every URL to 23
chars, so the dry-run figure is marked `(approx)` — the platform is the final arbiter.

### Don't trace these scripts

Both `social-post` and `reddit-submit` start with `set +x` to defuse the most common
leak: running `bash -x scripts/social-post …` (or setting `set -x` in your shell first)
would otherwise echo every gopass-loaded secret and every OAuth token to stderr. The
guard is defensive — if you really need to trace, do it on a copy with credentials
unset, never on a real send.

### Research vs. publish vs. DM — the boundary

This toolchain is intentionally **broadcast-publish only**. Two adjacent concerns sit
outside it:

- **Research / discovery** belongs to the `xurl` skill (X reads: search, profile,
  timeline). xurl is read-only — use it to find who's already discussing your niche,
  not to drive outbound automation.
- **One-to-one outreach (DM / reply / follow / like / repost)** is **always manual**
  in the platform UI. Automated DMs in particular are flagged by every platform's
  ToS (X, LinkedIn, Reddit) and most data-protection regimes (GDPR / ePrivacy /
  PIPL); they get accounts suspended and convert poorly. The healthy pattern is:
  `xurl` search → triage → **public reply / quote** to a relevant tweet → if
  someone clearly signals interest, one hand-written DM. Never templated, never
  batched, never via this toolchain.
