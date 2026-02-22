## 1. Websearch Startup Safety

- [x] 1.1 Set managed `oh-my-opencode` default websearch provider to startup-safe mode (`exa`).
- [x] 1.2 Update rendering tests to assert the managed default provider.

## 2. Diagnostics Hardening

- [x] 2.1 Extend `opencode-manage doctor` with provider-specific Tavily readiness warning behavior.
- [x] 2.2 Ensure doctor summary lines render readable status formatting for all three manage scripts.

## 3. Script Safety Improvements

- [x] 3.1 Replace variable-interpolated `printf` format strings in account-removal prompts with format-safe form.

## 4. Documentation and Verification

- [x] 4.1 Update OpenCode provider docs to reflect default provider and Tavily requirement guidance.
- [x] 4.2 Run full tests and script checks (`bash tests/run.sh`, syntax checks, doctor commands).
- [x] 4.3 Validate OpenSpec change artifacts (`openspec validate --changes`).
