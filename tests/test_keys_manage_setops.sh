#!/usr/bin/env bash
set -euo pipefail

# set_contains gates `rm -f` on encrypted backups during `keys-manage sync`, so its
# semantics are load-bearing: a false negative deletes a file that is still selected.
# It replaced associative arrays, which macOS's bash 3.2 does not have — so the suite
# also re-runs it under /bin/bash when that is an older bash than the one running here.

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
CORE="$ROOT/dot_local/bin/lib/keys-manage/core.sh"

run_cases() {
    # Pull the shipped helper out of core.sh rather than restating it, so this test
    # fails if the real implementation drifts.
    eval "$(awk '/^set_contains\(\) \{/,/^\}/' "$CORE")"

    local fail=0
    check() { # check <expected rc> <description> <haystack> <needle>
        local expect="$1" desc="$2" hay="$3" needle="$4" rc=0
        set_contains "$hay" "$needle" || rc=$?
        if [[ "$rc" != "$expect" ]]; then
            echo "  FAIL [$BASH_VERSION] $desc (rc=$rc, want=$expect)" >&2
            fail=1
        fi
    }

    local set_of_paths
    set_of_paths=$'.ssh/id_ed25519\n.gnupg/pubring.kbx\n.config/age/keys.txt\n'

    check 0 "member: first" "$set_of_paths" ".ssh/id_ed25519"
    check 0 "member: middle" "$set_of_paths" ".gnupg/pubring.kbx"
    check 0 "member: last" "$set_of_paths" ".config/age/keys.txt"
    check 1 "non-member" "$set_of_paths" ".ssh/id_rsa"

    # Partial matches must not count, or sync would keep files it should delete.
    check 1 "prefix is not a member" "$set_of_paths" ".ssh"
    check 1 "suffix is not a member" "$set_of_paths" "id_ed25519"
    check 1 "infix is not a member" "$set_of_paths" "age"

    check 1 "empty needle" "$set_of_paths" ""
    check 1 "empty set" "" ".ssh/id_ed25519"
    check 0 "member containing spaces" $'a b/c d\n' "a b/c d"

    # The needle is interpolated into a case pattern; it must stay literal or a path
    # with glob metacharacters would match the wrong entry.
    check 0 "glob metacharacters are literal" $'.cfg/foo[1]\n' ".cfg/foo[1]"
    check 1 "bracket expression does not expand" $'.cfg/foo1\n' ".cfg/foo[1]"
    check 1 "star does not act as a wildcard" $'.cfg/anything\n' "*"
    check 1 "question mark does not act as a wildcard" $'.cfg/ab\n' ".cfg/a?"

    return "$fail"
}

run_cases || exit 1

# `--inner` marks the re-run below so it neither recurses nor prints a second OK line.
if [[ "${1:-}" == "--inner" ]]; then
    exit 0
fi

# Re-run under macOS's system bash when it is a different (older) interpreter, since
# that is what `#!/usr/bin/env bash` actually resolves to on this platform.
if [[ -x /bin/bash ]] && [[ "$(/bin/bash -c 'echo ${BASH_VERSINFO[0]}')" != "${BASH_VERSINFO[0]}" ]]; then
    /bin/bash "${BASH_SOURCE[0]}" --inner || exit 1
fi

echo "test_keys_manage_setops: OK"
