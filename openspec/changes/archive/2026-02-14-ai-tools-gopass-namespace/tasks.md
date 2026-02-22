## 1. Namespace and Path Core

- [x] 1.1 Implement tool-context gopass prefix resolver and validation in `dot_local/bin/lib/ai/core.tmpl`
- [x] 1.2 Use canonical path generator `<prefix>/providers/<provider>/accounts/<encoded_account>/api_key` in `dot_local/bin/lib/ai/core.tmpl`
- [x] 1.3 Keep key operations (`get_api_key`, `store_api_key`, `delete_api_key`, `key_exists`) on canonical helpers only

## 2. Migration Strategy Alignment

- [x] 2.1 Align migration strategy to current workflow: managed key rewrite via `*-manage add-key`
- [x] 2.2 Confirm no dedicated migration binary is required by current repository behavior

## 3. Documentation

- [x] 3.1 Document current namespace behavior and migration notes in provider docs
- [x] 3.2 Remove outdated `AI_TOOLS_GOPASS_PREFIX` guidance to match implementation

## 4. Verification

- [x] 4.1 Verify canonical namespace behavior with existing wrapper tests
- [x] 4.2 Run `bash tests/run.sh`
- [x] 4.3 Run `openspec validate --changes ai-tools-gopass-namespace`
