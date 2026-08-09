#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import os
import pathlib
import shutil
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True


ROOT = pathlib.Path(__file__).resolve().parents[1]
UPDATER = ROOT / ".github" / "scripts" / "update_versions.py"
VERSIONS = ROOT / ".chezmoidata" / "versions.yaml"


def load_module():
    spec = importlib.util.spec_from_file_location("update_versions", UPDATER)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def parse_values(path: pathlib.Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("  ") or ":" not in line:
            continue
        key, value = line.strip().split(":", 1)
        values[key] = value.strip().strip('"')
    return values


def run_updater(path: pathlib.Path, env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", str(UPDATER), str(path)],
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def main() -> None:
    module = load_module()
    current = parse_values(VERSIONS)
    env = os.environ.copy()
    for key, env_name in module.ENV_BY_KEY.items():
        env[env_name] = current[key]

    tmp_root = pathlib.Path(tempfile.mkdtemp(prefix="update-versions-test."))
    try:
        candidate = tmp_root / "versions.yaml"
        shutil.copy2(VERSIONS, candidate)
        original_mode = stat.S_IMODE(candidate.stat().st_mode)
        env["U_PAPERLIB"] = "9.8.7"
        env["U_PAPERLIB_AMD64_SHA256"] = "a" * 64
        env["U_PAPERLIB_ARM64_SHA256"] = "b" * 64
        result = run_updater(candidate, env)
        assert result.returncode == 0, result.stderr
        updated = parse_values(candidate)
        assert updated["paperlib"] == "9.8.7"
        assert updated["paperlibAmd64Sha256"] == "a" * 64
        assert updated["paperlibArm64Sha256"] == "b" * 64
        assert stat.S_IMODE(candidate.stat().st_mode) == original_mode

        # An upstream tag containing shell syntax is rejected before any write.
        before = candidate.read_bytes()
        env["U_PAPERLIB"] = "3.1.12'; shell-syntax; #"
        result = run_updater(candidate, env)
        assert result.returncode != 0
        assert candidate.read_bytes() == before

        # Missing or duplicate keys fail atomically instead of partially
        # coupling a new version with old checksums.
        env["U_PAPERLIB"] = "9.8.8"
        missing = tmp_root / "missing.yaml"
        missing.write_text(
            VERSIONS.read_text(encoding="utf-8").replace(
                f"  paperlibArm64Sha256: {current['paperlibArm64Sha256']}\n", ""
            ),
            encoding="utf-8",
        )
        before = missing.read_bytes()
        result = run_updater(missing, env)
        assert result.returncode != 0
        assert missing.read_bytes() == before

        duplicate = tmp_root / "duplicate.yaml"
        shutil.copy2(VERSIONS, duplicate)
        with duplicate.open("a", encoding="utf-8") as handle:
            handle.write(f"  paperlib: {current['paperlib']}\n")
        before = duplicate.read_bytes()
        result = run_updater(duplicate, env)
        assert result.returncode != 0
        assert duplicate.read_bytes() == before


        print("test_update_versions: OK")
    finally:
        shutil.rmtree(tmp_root)


if __name__ == "__main__":
    main()
