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
| `social-post`   | `dot_local/bin`                       | The gate. `social-post <platform> --file … [--yes]`. |
| `crosspost`     | `npm:@humanwhocodes/crosspost` (mise) | Multi-platform publish engine.                       |
| `reddit-submit` | `dot_local/bin`                       | Narrow Reddit OAuth submit helper.                   |
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
  reddit-submit auth-url --client-id <id>      # open URL, authorize, copy the code
  reddit-submit exchange-code --client-id <id> --code <code>
  # store the refresh_token from the output in gopass: social/reddit/refresh_token
  ```

## Usage

```bash
# preview (dry-run, no credentials needed)
social-post bluesky --file tmp/launch/bluesky.md

# publish after review
social-post bluesky --file tmp/launch/bluesky.md --yes
social-post reddit  --subreddit rust --title "<title>" --file tmp/launch/reddit-rust.md --yes
```

Or drive the whole flow with the `oss-launch` skill / `/social-publish` command, which
drafts every platform from one topic, waits for your approval, then sends through
`social-post`.

## Safety

`social-post` enforces: dry-run by default, length limits per platform, post-only (no
reply/DM/follow/like/repost), and a single send attempt (no retry loops). One topic is
rewritten per platform — identical text is never blasted everywhere. These mirror the
X automation rules and avoid spam/bot flags.
