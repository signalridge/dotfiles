#!/usr/bin/env python3
"""Validate and atomically update pinned values in versions.yaml."""

from __future__ import annotations

import os
import pathlib
import re
import stat
import sys
import tempfile


ENV_BY_KEY = {
    "nixInstaller": "U_NIX_INSTALLER",
    "nixInstallerAarch64DarwinSha256": "U_NIX_INSTALLER_AARCH64_DARWIN_SHA256",
    "nixInstallerAarch64LinuxSha256": "U_NIX_INSTALLER_AARCH64_LINUX_SHA256",
    "nixInstallerX8664LinuxSha256": "U_NIX_INSTALLER_X86_64_LINUX_SHA256",
    "nixVersion": "U_NIX_VERSION",
    "nixpkgsBootstrapRev": "U_NIXPKGS_BOOTSTRAP_REV",
    "aquaInstaller": "U_AQUA_INSTALLER",
    "aquaInstallerSha256": "U_AQUA_INSTALLER_SHA256",
    "aquaVersion": "U_AQUA_VERSION",
    "nixIndexDb": "U_NIX_INDEX_DB",
    "paperlib": "U_PAPERLIB",
    "paperlibAmd64Sha256": "U_PAPERLIB_AMD64_SHA256",
    "paperlibArm64Sha256": "U_PAPERLIB_ARM64_SHA256",
    "cursorAgentVersion": "U_CURSOR_AGENT_VERSION",
    "cursorAgentDarwinArm64Sha256": "U_CURSOR_AGENT_DARWIN_ARM64_SHA256",
    "cursorAgentDarwinX64Sha256": "U_CURSOR_AGENT_DARWIN_X64_SHA256",
    "cursorAgentLinuxArm64Sha256": "U_CURSOR_AGENT_LINUX_ARM64_SHA256",
    "cursorAgentLinuxX64Sha256": "U_CURSOR_AGENT_LINUX_X64_SHA256",
    "tpmRev": "U_TPM_REV",
    "tpmSha256": "U_TPM_SHA256",
    "claudeWshobsonAgentsRev": "U_CLAUDE_WSHOBSON_AGENTS_REV",
    "claudeWshobsonAgentsSha256": "U_CLAUDE_WSHOBSON_AGENTS_SHA256",
    "claudeAnthropicsSkillsRev": "U_CLAUDE_ANTHROPICS_SKILLS_REV",
    "claudeAnthropicsSkillsSha256": "U_CLAUDE_ANTHROPICS_SKILLS_SHA256",
    "uiUxProMaxSkillRev": "U_UI_UX_PRO_MAX_SKILL_REV",
    "uiUxProMaxSkillSha256": "U_UI_UX_PRO_MAX_SKILL_SHA256",
    "openaiSkillsRev": "U_OPENAI_SKILLS_REV",
    "huggingfaceSkillsRev": "U_HUGGINGFACE_SKILLS_REV",
    "getsentrySkillsRev": "U_GETSENTRY_SKILLS_REV",
    "trailofbitsSkillsRev": "U_TRAILOFBITS_SKILLS_REV",
    "cloudflareSkillsRev": "U_CLOUDFLARE_SKILLS_REV",
    "vercelLabsAgentSkillsRev": "U_VERCEL_LABS_AGENT_SKILLS_REV",
    "vercelLabsNextSkillsRev": "U_VERCEL_LABS_NEXT_SKILLS_REV",
    "vercelLabsAgentBrowserRev": "U_VERCEL_LABS_AGENT_BROWSER_REV",
    "supabaseAgentSkillsRev": "U_SUPABASE_AGENT_SKILLS_REV",
    "expoSkillsRev": "U_EXPO_SKILLS_REV",
    "microsoftSkillsRev": "U_MICROSOFT_SKILLS_REV",
    "zigDevelopmentPlaybookSkillRev": "U_ZIG_DEVELOPMENT_PLAYBOOK_SKILL_REV",
    "rustDevelopmentPlaybookSkillRev": "U_RUST_DEVELOPMENT_PLAYBOOK_SKILL_REV",
    "claudeBaoyuSkillsRev": "U_CLAUDE_BAOYU_SKILLS_REV",
    "phurynPmSkillsRev": "U_PHURYN_PM_SKILLS_REV",
    "opcSkillsRev": "U_OPC_SKILLS_REV",
    "xSkillsRev": "U_X_SKILLS_REV",
    "xurlSkillRev": "U_XURL_SKILL_REV",
    "dailyDevSkillsRev": "U_DAILY_DEV_SKILLS_REV",
    "samberCcSkillsGolangRev": "U_SAMBER_CC_SKILLS_GOLANG_REV",
    "affaanEccRev": "U_AFFAAN_ECC_REV",
    "actionbookRustSkillsRev": "U_ACTIONBOOK_RUST_SKILLS_REV",
    "dpearsonSwiftSkillsRev": "U_DPEARSON_SWIFT_SKILLS_REV",
    "effectiveTypescriptRev": "U_EFFECTIVE_TYPESCRIPT_REV",
    "bobmatnycMpmSkillsRev": "U_BOBMATNYC_MPM_SKILLS_REV",
    "humanizerEnRev": "U_HUMANIZER_EN_REV",
    "quAiWeiRev": "U_QU_AI_WEI_REV",
    "humanizerJaRev": "U_HUMANIZER_JA_REV",
}

HEX_40_RE = re.compile(r"[0-9a-f]{40}")
HEX_64_RE = re.compile(r"[0-9a-f]{64}")
SEMVER_RE = re.compile(
    r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?"
)
CURSOR_VERSION_RE = re.compile(
    r"[0-9]{4}\.(?:0[1-9]|1[0-2])\.(?:0[1-9]|[12][0-9]|3[01])-[0-9a-f]{7}"
)
SAFE_TAG_RE = re.compile(r"[0-9A-Za-z][0-9A-Za-z._+-]{0,127}")


def validate_value(key: str, value: str) -> None:
    if key.endswith("Sha256"):
        pattern, kind = HEX_64_RE, "SHA-256"
    elif key.endswith("Rev"):
        pattern, kind = HEX_40_RE, "commit SHA"
    elif key == "paperlib":
        pattern, kind = SEMVER_RE, "semantic version"
    elif key == "cursorAgentVersion":
        pattern, kind = CURSOR_VERSION_RE, "Cursor Agent version"
    else:
        pattern, kind = SAFE_TAG_RE, "release tag"

    if pattern.fullmatch(value) is None:
        raise ValueError(f"invalid {kind} for {key}: {value!r}")


def load_updates() -> dict[str, str]:
    updates: dict[str, str] = {}
    for key, env_name in ENV_BY_KEY.items():
        try:
            value = os.environ[env_name]
        except KeyError as exc:
            raise ValueError(f"missing environment variable: {env_name}") from exc
        validate_value(key, value)
        updates[key] = value
    return updates


def update_file(path: pathlib.Path, updates: dict[str, str]) -> None:
    original = path.read_text(encoding="utf-8")
    lines = original.splitlines(keepends=True)
    counts = dict.fromkeys(updates, 0)
    patterns = {
        key: re.compile(rf"^(?P<indent>\s*){re.escape(key)}:\s*.*$")
        for key in updates
    }

    rendered: list[str] = []
    for line in lines:
        body = line.rstrip("\r\n")
        ending = line[len(body) :]
        matched_key = None
        matched_indent = ""
        for key, pattern in patterns.items():
            match = pattern.fullmatch(body)
            if match is not None:
                matched_key = key
                matched_indent = match.group("indent")
                break
        if matched_key is None:
            rendered.append(line)
            continue
        counts[matched_key] += 1
        rendered.append(f"{matched_indent}{matched_key}: {updates[matched_key]}{ending}")

    invalid_counts = {key: count for key, count in counts.items() if count != 1}
    if invalid_counts:
        raise ValueError(f"each version key must occur exactly once: {invalid_counts}")

    new_content = "".join(rendered)
    if not new_content.endswith("\n"):
        new_content += "\n"

    mode = stat.S_IMODE(path.stat().st_mode)
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temp_path = pathlib.Path(temp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
            os.fchmod(handle.fileno(), mode)
            handle.write(new_content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_path, path)
    finally:
        temp_path.unlink(missing_ok=True)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"usage: {argv[0]} VERSIONS_YAML", file=sys.stderr)
        return 2
    try:
        update_file(pathlib.Path(argv[1]), load_updates())
    except (OSError, ValueError) as exc:
        print(f"update_versions: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
