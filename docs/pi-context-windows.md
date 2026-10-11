# Pi context windows

Pi's automatic compaction threshold is:

```text
contextTokens > contextWindow - reserveTokens
```

A model catalog value, a public API's total context window, and the input capacity
of a subscription/OAuth endpoint are not interchangeable.

## Codex OAuth probes — 2026-10-11

Tested with the installed Pi 1.1.0 `ModelRuntime.completeSimple`, native
`openai-codex` OAuth authentication, and the `openai-codex-responses` adapter at
`https://chatgpt.com/backend-api/codex/responses`. Requests used SSE, synthetic
`" x"` padding, a short instruction to return `OK`, no tools, no automatic input
truncation, and no `max_output_tokens` field. No repository or conversation
content was submitted. Credentials were resolved internally, not printed or
saved in this repository.

| Model           | Reasoning | Accepted input tokens (server usage) | Rejected padding repetitions |
| --------------- | --------- | -----------------------------------: | ---------------------------: |
| `gpt-6.1-sol`   | high      |                     870,065; 921,065 |             922,000; 930,000 |
| `gpt-6-astra`   | medium    |                              921,065 |                      922,000 |
| `gpt-5.6-sol`   | high      |                              921,065 |                 Not retested |
| `gpt-5.6-terra` | high      |                              921,065 |                 Not retested |

All accepted requests returned `OK`. Rejections reported:

```text
Codex error: Your input exceeds the context window of this model.
Please adjust your input and try again.
```

For Sol, increasing padding by 51,000 repetitions increased reported input by
exactly 51,000 tokens. The rejected 922,000-repetition request therefore contains
approximately 922,065 input tokens with the same framing. Rejected requests
report no usage, so that count is inferred, not server-reported. The experiment
brackets the input wall near 922K; it does not establish an exact maximum or test
long-context recall quality. It also does not prove a 128K output allowance on
this account: that remains model catalog metadata.

## Managed configuration

`.chezmoidata/pi.yaml` supplies metadata-only `modelOverrides` for native Codex
models. The Sol and Astra windows are conservatively pinned to **921,000**, below
the largest successfully tested input. Native OAuth, reasoning levels, pricing,
and output metadata remain intact; no replacement model definition or API key
is introduced.

Reserves are configured with exact `provider/model` compaction overrides, not a
global 130K value. Sol and Astra each reserve **130,000**, making their threshold
**791,000**, rather than the previous **142,000**. Other explicitly configured
models use their own window/output budget: 1M models reserve 130K; 256K Kimi
models reserve 49,152; Qwen Max reserves 81,920; Doubao reserves 32,768. Unspecified
models use a **16,384** baseline. Thus Spark's 128K window has a positive
**111,616** threshold, not the previous **−2,000**.
The same metadata reaches the parent, ordinary subagents, and workflow-managed
subagents through Pi's model runtime; they do not need separate window pins.

Do not set the OAuth input capacity to the public API's 1,050,000 total-context
value. With this reserve, that would delay compaction to 920K, only about 2K below
the observed input wall. Keep headroom for output, reasoning, and new tool
results. Pi 1.1.0 checks projected context between tool batches, before the next
assistant response; old comments claiming it never checks between tools no
longer apply. No extra compaction extension is needed.

Longer contexts can consume more subscription quota. Public API prices and Pi's
estimated cost counters are not measurements of this OAuth account's billing.
Historical `gpt-5.6-luna` measurements are documented separately in the source
configuration; do not infer another model's limit from them.

## Harness's CPA route

Separately probed the configured local CLIProxyAPI `/v1/responses` route with
Sol/high reasoning, no tools, and no `max_output_tokens`. It accepted **921,361**
input tokens and returned `OK`; 922,000 padding repetitions were rejected.
Proxy framing differs from the native adapter, so server usage differs too.
Harness now declares the same conservative **921,000** input window and native
**128,000** output metadata, rather than an unverified 1M input window and a 32K
output declaration that was never transmitted as a cap. These output tokens
inform dsh's completion reservation; they do not enforce an upstream maximum.

## Apply and verify

Apply only the managed Pi files, without running unrelated chezmoi scripts:

```sh
chezmoi apply --include=files ~/.pi/agent/models.json ~/.pi/agent/settings.json
pi --list-models gpt-6.1-sol
```

A newly started Pi uses both the new metadata and per-model reserves. The
simplest activation is to quit Pi and resume with `pi -c`. In an existing session,
run `/reload` to refresh settings, then open `/model`, wait for its catalog
refresh to finish, and reselect the model. `/reload` alone does not refresh model
metadata; `/model` alone does not refresh compaction settings. Already-created
subagents may retain old settings/model objects: let them finish and start new
agents. Previous compactions cannot restore old history verbatim; this change
prevents premature future compactions.

This configuration repository keeps formatting, syntax, and secret checks rather
than a mock/stub regression suite. Probe scripts are temporary, not managed
configuration or checked-in tests.
