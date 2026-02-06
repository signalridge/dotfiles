#!/usr/bin/env python3
import hashlib
import json
import os
import pathlib
import pty
import select
import shutil
import subprocess
import sys
import tempfile
import time


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT_TMPL = REPO_ROOT / ".chezmoiscripts" / "run_before_01_setup-encryption-key.sh.tmpl"

PASS = "test-pass-123"


def sha256_file(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def run_with_pty(cmd, env, input_bytes: bytes, timeout_sec: int = 60):
    master, slave = pty.openpty()
    try:
        p = subprocess.Popen(cmd, stdin=slave, stdout=slave, stderr=slave, env=env)
    finally:
        os.close(slave)

    out = bytearray()
    if input_bytes:
        os.write(master, input_bytes)

    deadline = time.time() + timeout_sec
    while True:
        if time.time() > deadline:
            p.kill()
            snippet = out.decode(errors="replace")[-2000:]
            raise RuntimeError(f"timeout (last output):\n{snippet}")

        r, _, _ = select.select([master], [], [], 0.1)
        if r:
            try:
                chunk = os.read(master, 4096)
            except OSError:
                chunk = b""
            if chunk:
                out.extend(chunk)

        if p.poll() is not None:
            # Drain any remaining output.
            while True:
                try:
                    chunk = os.read(master, 4096)
                except OSError:
                    chunk = b""
                if not chunk:
                    break
                out.extend(chunk)
            break

    os.close(master)
    rc = p.wait()
    return rc, out.decode(errors="replace")


def run_with_pty_steps(cmd, env, steps, timeout_sec: int = 60):
    """Run a command with a PTY, sending inputs after matching output patterns.

    steps: list[tuple[str, bytes]] of (pattern, bytes_to_send)
    """
    master, slave = pty.openpty()
    try:
        p = subprocess.Popen(cmd, stdin=slave, stdout=slave, stderr=slave, env=env)
    finally:
        os.close(slave)

    out = bytearray()
    text_buf = ""
    search_from = 0
    step_idx = 0

    deadline = time.time() + timeout_sec
    while True:
        if time.time() > deadline:
            p.kill()
            snippet = out.decode(errors="replace")[-2000:]
            raise RuntimeError(f"timeout (last output):\n{snippet}")

        r, _, _ = select.select([master], [], [], 0.1)
        if r:
            try:
                chunk = os.read(master, 4096)
            except OSError:
                chunk = b""
            if chunk:
                out.extend(chunk)
                text_buf += chunk.decode(errors="replace")

                while step_idx < len(steps):
                    pattern, payload = steps[step_idx]
                    pos = text_buf.find(pattern, search_from)
                    if pos == -1:
                        break
                    search_from = pos + len(pattern)
                    os.write(master, payload)
                    step_idx += 1

        if p.poll() is not None:
            # Drain any remaining output.
            while True:
                try:
                    chunk = os.read(master, 4096)
                except OSError:
                    chunk = b""
                if not chunk:
                    break
                out.extend(chunk)
            break

    os.close(master)
    rc = p.wait()
    return rc, out.decode(errors="replace")


def git(cmd, cwd: pathlib.Path):
    subprocess.check_call(["git"] + cmd, cwd=str(cwd), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def openssl_encrypt(src: pathlib.Path, dst: pathlib.Path, password: str):
    dst.parent.mkdir(parents=True, exist_ok=True)
    subprocess.check_call(
        [
            "openssl",
            "enc",
            "-aes-256-cbc",
            "-pbkdf2",
            "-iter",
            "100000",
            "-salt",
            "-pass",
            f"pass:{password}",
            "-in",
            str(src),
            "-out",
            str(dst),
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def gen_ssh_keypair(dir_path: pathlib.Path, name: str) -> pathlib.Path:
    dir_path.mkdir(parents=True, exist_ok=True)
    key_path = dir_path / name
    subprocess.check_call(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(key_path)], stdout=subprocess.DEVNULL)
    return key_path


def make_keys_repo(repo_dir: pathlib.Path, home: pathlib.Path, key_src: pathlib.Path):
    repo_dir.mkdir(parents=True, exist_ok=True)
    git(["init", "-b", "main"], repo_dir)

    backup_files = repo_dir / "backup-files"
    backup_list = repo_dir / "backup-list.txt"
    meta_file = repo_dir / "backup-metadata.json"
    gitignore = repo_dir / ".gitignore"

    target = home / ".ssh" / "main"
    pub_src = pathlib.Path(str(key_src) + ".pub")

    backup_list.write_text(".ssh/main\n.ssh/main.pub\n", encoding="utf-8")

    openssl_encrypt(key_src, backup_files / ".ssh" / "main", PASS)
    openssl_encrypt(pub_src, backup_files / ".ssh" / "main.pub", PASS)

    meta = {
        "version": 2,
        "filters": {
            "include_patterns": ["*"],
            "exclude_patterns": ["*.pub", "known_hosts*", "authorized_keys*"],
            "custom_paths": [],
        },
        "files": {
            ".ssh/main": {
                "sha256": sha256_file(key_src),
                "size": key_src.stat().st_size,
                "mtime": int(key_src.stat().st_mtime),
                "permissions": "600",
                "last_backup": "2026-02-04T00:00:00Z",
                "backup_count": 1,
            },
            ".ssh/main.pub": {
                "sha256": sha256_file(pub_src),
                "size": pub_src.stat().st_size,
                "mtime": int(pub_src.stat().st_mtime),
                "permissions": "644",
                "last_backup": "2026-02-04T00:00:00Z",
                "backup_count": 1,
            }
        },
    }

    meta_file.write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")

    # Track only encrypted control files in git; keep plaintext working copies local+ignored.
    gitignore.write_text(".keys-manage/\nbackup-list.txt\nbackup-metadata.json\n", encoding="utf-8")
    openssl_encrypt(backup_list, repo_dir / "backup-list.txt.enc", PASS)
    openssl_encrypt(meta_file, repo_dir / "backup-metadata.json.enc", PASS)

    git(["add", "backup-files", "backup-list.txt.enc", "backup-metadata.json.enc", ".gitignore"], repo_dir)
    git(["commit", "-m", "init"], repo_dir)


def assert_eq(a, b, msg):
    if a != b:
        raise AssertionError(msg)


def main():
    tmp_root = pathlib.Path(tempfile.mkdtemp(prefix="keys-setup-test."))
    try:
        # Render the chezmoi template to a runnable script.
        rendered = tmp_root / "run_once_before_01_setup-encryption-key.sh"
        rendered.write_bytes(
            subprocess.check_output(
                ["chezmoi", "execute-template", "--source", str(REPO_ROOT)], input=SCRIPT_TMPL.read_bytes()
            )
        )
        os.chmod(rendered, 0o755)

        # Scenario 1: missing file gets restored.
        home1 = tmp_root / "home1"
        repo1 = tmp_root / "repo1"
        key1 = gen_ssh_keypair(tmp_root / "gen", "key1")
        make_keys_repo(repo1, home1, key1)

        env1 = os.environ.copy()
        env1.update(
            {
                "HOME": str(home1),
                "KEYS_REPO": str(repo1),
                "KEYS_BACKUP_PASSWORD": PASS,
            }
        )

        rc, out = run_with_pty(["bash", str(rendered)], env=env1, input_bytes=b"y\n")
        if rc != 0:
            sys.stderr.write(out)
            raise SystemExit(f"scenario1 failed rc={rc}")

        restored_priv = home1 / ".ssh" / "main"
        restored_pub = home1 / ".ssh" / "main.pub"
        assert restored_priv.exists(), "private key not restored"
        assert restored_pub.exists(), "pub key not restored"
        assert_eq(restored_priv.read_bytes(), key1.read_bytes(), "private key content mismatch")
        assert_eq(
            restored_pub.read_bytes(),
            pathlib.Path(str(key1) + ".pub").read_bytes(),
            "pub key content mismatch",
        )

        # Scenario 2: differing local file -> user declines overwrite; should keep local (and pub).
        home2 = tmp_root / "home2"
        repo2 = tmp_root / "repo2"
        key_backup = gen_ssh_keypair(tmp_root / "gen", "key_backup")
        make_keys_repo(repo2, home2, key_backup)

        local_key = gen_ssh_keypair(home2 / ".ssh", "main")
        assert local_key.read_bytes() != key_backup.read_bytes(), "test setup error: keys unexpectedly equal"

        env2 = os.environ.copy()
        env2.update(
            {
                "HOME": str(home2),
                "KEYS_REPO": str(repo2),
                "KEYS_BACKUP_PASSWORD": PASS,
            }
        )

        rc2, out2 = run_with_pty(["bash", str(rendered)], env=env2, input_bytes=b"y\nn\nn\n")
        if rc2 != 0:
            sys.stderr.write(out2)
            raise SystemExit(f"scenario2 failed rc={rc2}")

        assert_eq((home2 / ".ssh" / "main").read_bytes(), local_key.read_bytes(), "local private key overwritten")
        assert_eq(
            (home2 / ".ssh" / "main.pub").read_bytes(),
            pathlib.Path(str(local_key) + ".pub").read_bytes(),
            "local pub key overwritten",
        )

        # Scenario 3: differing local file -> user accepts overwrite; snapshot is created.
        home3 = tmp_root / "home3"
        repo3 = tmp_root / "repo3"
        key_backup3 = gen_ssh_keypair(tmp_root / "gen", "key_backup3")
        make_keys_repo(repo3, home3, key_backup3)

        local_key3 = gen_ssh_keypair(home3 / ".ssh", "main")
        local_before_priv = local_key3.read_bytes()
        local_before_pub = pathlib.Path(str(local_key3) + ".pub").read_bytes()

        env3 = os.environ.copy()
        env3.update(
            {
                "HOME": str(home3),
                "KEYS_REPO": str(repo3),
                "KEYS_BACKUP_PASSWORD": PASS,
            }
        )

        # Prompts: (1) proceed restore, (2) overwrite private key, (3) overwrite public key
        rc3, out3 = run_with_pty(["bash", str(rendered)], env=env3, input_bytes=b"y\ny\ny\n")
        if rc3 != 0:
            sys.stderr.write(out3)
            raise SystemExit(f"scenario3 failed rc={rc3}")

        assert_eq((home3 / ".ssh" / "main").read_bytes(), key_backup3.read_bytes(), "private key not overwritten")
        assert_eq(
            (home3 / ".ssh" / "main.pub").read_bytes(),
            pathlib.Path(str(key_backup3) + ".pub").read_bytes(),
            "pub key not overwritten",
        )

        snaps = sorted((home3 / ".local" / "share" / "keys-backup" / "restore-snapshots").glob("*"))
        assert snaps, "expected restore snapshot directory to be created"
        snap = snaps[-1]
        snap_priv = snap / ".ssh" / "main"
        snap_pub = snap / ".ssh" / "main.pub"
        assert snap_priv.exists(), "snapshot private key missing"
        assert snap_pub.exists(), "snapshot public key missing"
        assert_eq(snap_priv.read_bytes(), local_before_priv, "snapshot private key content mismatch")
        assert_eq(snap_pub.read_bytes(), local_before_pub, "snapshot public key content mismatch")

        # Scenario 4: interactive prompt retries on wrong password.
        home4 = tmp_root / "home4"
        repo4 = tmp_root / "repo4"
        key4 = gen_ssh_keypair(tmp_root / "gen", "key4")
        make_keys_repo(repo4, home4, key4)

        env4 = os.environ.copy()
        env4.update(
            {
                "HOME": str(home4),
                "KEYS_REPO": str(repo4),
            }
        )

        rc4, out4 = run_with_pty_steps(
            ["bash", str(rendered)],
            env=env4,
            steps=[
                ("Enter keys-backup encryption password:", b"wrong-pass\r"),
                ("Enter keys-backup encryption password:", PASS.encode() + b"\r"),
                ("Restore missing/changed files now?", b"y\r"),
            ],
        )
        if rc4 != 0:
            sys.stderr.write(out4)
            raise SystemExit(f"scenario4 failed rc={rc4}")

        assert (home4 / ".ssh" / "main").exists(), "scenario4: private key not restored"
        assert (home4 / ".ssh" / "main.pub").exists(), "scenario4: pub key not restored"

        # Scenario 5: wrong password does not leave corrupted plaintext control files behind.
        home5 = tmp_root / "home5"
        repo5 = tmp_root / "repo5"
        key5 = gen_ssh_keypair(tmp_root / "gen", "key5")
        make_keys_repo(repo5, home5, key5)

        env5 = os.environ.copy()
        env5.update(
            {
                "HOME": str(home5),
                "KEYS_REPO": str(repo5),
            }
        )

        rc5, _ = run_with_pty_steps(
            ["bash", str(rendered)],
            env=env5,
            steps=[
                ("Enter keys-backup encryption password:", b"wrong1\r"),
                ("Enter keys-backup encryption password:", b"wrong2\r"),
                ("Enter keys-backup encryption password:", b"wrong3\r"),
            ],
        )
        if rc5 == 0:
            raise SystemExit("scenario5 failed: expected non-zero rc for wrong password")

        plain_list = home5 / ".local" / "share" / "keys-backup" / "backup-list.txt"
        assert not plain_list.exists(), "scenario5: backup-list.txt should not exist after failed decrypt"

        # Scenario 6: wrong env var password fails without leaving plaintext control files behind.
        home6 = tmp_root / "home6"
        repo6 = tmp_root / "repo6"
        key6 = gen_ssh_keypair(tmp_root / "gen", "key6")
        make_keys_repo(repo6, home6, key6)

        env6 = os.environ.copy()
        env6.update(
            {
                "HOME": str(home6),
                "KEYS_REPO": str(repo6),
                "KEYS_BACKUP_PASSWORD": "wrong-env-pass",
            }
        )

        rc6, _ = run_with_pty(["bash", str(rendered)], env=env6, input_bytes=b"")
        if rc6 == 0:
            raise SystemExit("scenario6 failed: expected non-zero rc for wrong env var password")

        plain_list6 = home6 / ".local" / "share" / "keys-backup" / "backup-list.txt"
        assert not plain_list6.exists(), "scenario6: backup-list.txt should not exist after failed decrypt"

        # Scenario 7: corrupted plaintext control file triggers re-decrypt (fast path must not hide it).
        home7 = tmp_root / "home7"
        repo7 = tmp_root / "repo7"
        key7 = gen_ssh_keypair(tmp_root / "gen", "key7")
        make_keys_repo(repo7, home7, key7)

        env7 = os.environ.copy()
        env7.update(
            {
                "HOME": str(home7),
                "KEYS_REPO": str(repo7),
                "KEYS_BACKUP_PASSWORD": PASS,
            }
        )

        rc7a, out7a = run_with_pty(["bash", str(rendered)], env=env7, input_bytes=b"y\n")
        if rc7a != 0:
            sys.stderr.write(out7a)
            raise SystemExit(f"scenario7a failed rc={rc7a}")

        expected_list = ".ssh/main\n.ssh/main.pub\n"
        plain_list7 = home7 / ".local" / "share" / "keys-backup" / "backup-list.txt"
        assert plain_list7.exists(), "scenario7: expected backup-list.txt to exist after successful run"
        plain_list7.write_bytes(b"\x00\xff\x00")

        rc7b, out7b = run_with_pty(["bash", str(rendered)], env=env7, input_bytes=b"\n")
        if rc7b != 0:
            sys.stderr.write(out7b)
            raise SystemExit(f"scenario7b failed rc={rc7b}")

        assert plain_list7.read_text(encoding="utf-8") == expected_list, "scenario7: control file not re-decrypted"

        print("test_setup_encryption_key: OK")
    finally:
        shutil.rmtree(tmp_root)


if __name__ == "__main__":
    main()
