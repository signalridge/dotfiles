# Security Policy

## Supported Scope

This repository is actively maintained on the `main` branch.

| Branch | Supported |
| ------ | --------- |
| `main` | Yes       |

## Reporting a Vulnerability

Please do **not** disclose vulnerabilities in public issues or pull requests.

Use GitHub private vulnerability reporting:

- https://github.com/signalridge/dotfiles/security/advisories/new

## What to Include

Please include:

- clear description of the issue
- impact assessment
- reproduction steps
- affected files/scripts/workflows
- suggested remediation (if available)

## Response Expectations

Maintainers will triage reports on a best-effort basis and aim to:

- acknowledge receipt within 72 hours
- provide an initial status update within 7 days
- coordinate remediation and disclosure timing with the reporter

## Security-Relevant Areas

The most sensitive areas in this repository include:

- bootstrap scripts under `.chezmoiscripts/`
- credential/key management scripts under `dot_local/bin/`
- encrypted/private material handling (`*.age`, key restore flow)
- CI automation and workflow permissions under `.github/workflows/`

## Out of Scope

- vulnerabilities in third-party services outside this repository
- social engineering attempts
- issues requiring direct access to your local machine that are not caused by this repository's code/configuration
