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
                 ├─ crosspost -<plat> --file …   (x, bluesky, mastodon, linkedin, devto)
                 └─ reddit-submit submit …       (reddit)
  └─ /social-publish         explicit command entry that runs the oss-launch flow
```

- **Auto-publish (API):** X, Bluesky, Mastodon, LinkedIn, dev.to, Reddit.
- **Prepare-only (no API / norms forbid auto-posting):** Hacker News (Show HN),
  Lobsters, Product Hunt launch, directories. The skill drafts + opens the page; you
  submit manually.
- **Repo ops:** GitHub via `gh`, GitLab via `glab`.

`xurl` is kept for X **reads** only (search / whoami / timeline). Writes never go
through `xurl post`; they go through `social-post`, which is the only posting path.

## Tools

| Tool            | Backend                               | Role                                                 |
| --------------- | ------------------------------------- | ---------------------------------------------------- |
| `social-post`   | `oss-launch` skill `scripts/`         | The gate. `social-post <platform> --file … [--yes]`. |
| `crosspost`     | `npm:@humanwhocodes/crosspost` (mise) | Multi-platform publish engine.                       |
| `reddit-submit` | `oss-launch` skill `scripts/`         | Narrow Reddit OAuth submit helper.                   |
| `xurl`          | `go:…/xurl` (mise)                    | X reads/research only.                               |

## Credentials (gopass)

Secrets are read from gopass at send time (never stored in the repo). Dry-run does
**not** need credentials, so you can preview without them. Each env var falls back
to gopass at the path below; you may also pre-export the env var.

| Platform | gopass paths                                                                         | crosspost / helper env                                                                                               |
| -------- | ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- |
| X        | `social/twitter/{consumer_key,consumer_secret,access_token_key,access_token_secret}` | `TWITTER_API_CONSUMER_KEY`, `TWITTER_API_CONSUMER_SECRET`, `TWITTER_ACCESS_TOKEN_KEY`, `TWITTER_ACCESS_TOKEN_SECRET` |
| Bluesky  | `social/bluesky/{identifier,password}` (optional `host`)                             | `BLUESKY_IDENTIFIER`, `BLUESKY_PASSWORD`, `BLUESKY_HOST`                                                             |
| Mastodon | `social/mastodon/{access_token,host}`                                                | `MASTODON_ACCESS_TOKEN`, `MASTODON_HOST`                                                                             |
| LinkedIn | `social/linkedin/access_token`                                                       | `LINKEDIN_ACCESS_TOKEN`                                                                                              |
| dev.to   | `social/devto/api_key`                                                               | `DEVTO_API_KEY`                                                                                                      |
| Reddit   | `social/reddit/{client_id,client_secret,refresh_token}` (optional `user_agent`)      | `REDDIT_CLIENT_ID`, `REDDIT_CLIENT_SECRET`, `REDDIT_REFRESH_TOKEN`, `REDDIT_USER_AGENT`                              |

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
  the Mastodon long-lived access token, the dev.to API key, and Reddit's `permanent`
  refresh token (revoke-only, does not rotate).
- Ephemeral tokens — Reddit's 1-hour access token, the Bluesky session JWT — are derived
  at runtime from the static secret and never touch gopass or any rendered config.

### Getting tokens

- **X:** create an app in the X developer portal, enable OAuth 1.0a user context with
  write, and copy the consumer key/secret + access token key/secret. Set a spending
  limit on the API.
- **Bluesky:** Settings → App Passwords → create one. Use your handle as identifier.
- **Mastodon:** Preferences → Development → New application with `write:statuses`; copy
  the access token. `host` is your instance, e.g. `mastodon.social`.
- **LinkedIn:** requires an approved app with `w_member_social`; copy the OAuth access
  token.
- **dev.to:** Settings → Extensions → DEV API keys → generate.
- **Reddit:** create a "script" app, then bootstrap a permanent refresh token with the
  existing helper:

  ```bash
  SKILL=~/.agents/skills/social-media/oss-x-post
  python3 "$SKILL/scripts/reddit-submit" auth-url --client-id <id>      # open URL, authorize, copy the code
  python3 "$SKILL/scripts/reddit-submit" exchange-code --client-id <id> --code <code>
  # store the refresh_token from the output in gopass: social/reddit/refresh_token
  ```

## Usage

```bash
SKILL=~/.agents/skills/social-media/oss-x-post

# preview (dry-run, no credentials needed)
python3 "$SKILL/scripts/social-post" bluesky --file tmp/launch/bluesky.md

# publish after review
python3 "$SKILL/scripts/social-post" bluesky --file tmp/launch/bluesky.md --yes
python3 "$SKILL/scripts/social-post" reddit  --subreddit rust --title "<title>" --file tmp/launch/reddit-rust.md --yes
```

Or drive the whole flow with the `oss-launch` skill / `/social-publish` command, which
drafts every platform from one topic, waits for your approval, then sends through
`social-post`.

## Safety

`social-post` enforces: dry-run by default, length limits per platform, post-only (no
reply/DM/follow/like/repost), and a single send attempt (no retry loops). One topic is
rewritten per platform — identical text is never blasted everywhere. These mirror the
X automation rules and avoid spam/bot flags.
