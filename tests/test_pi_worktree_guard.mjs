import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  commandAddsWorktree,
  findWorktreeForbiddenRoot,
  workflowRequestsWorktree,
} from "../dot_pi/agent/extensions/pi-worktree-guard.ts";

const root = mkdtempSync(join(tmpdir(), "pi-worktree-guard-"));
try {
  mkdirSync(join(root, ".chezmoidata"));
  mkdirSync(join(root, "nested", "deeper"), { recursive: true });
  writeFileSync(
    join(root, "AGENTS.md"),
    "# Rules\nNO git worktrees. Ever.\nNEVER run `git worktree add` in this repo.\n",
  );

  assert.equal(findWorktreeForbiddenRoot(join(root, "nested", "deeper")), root);
  assert.equal(workflowRequestsWorktree("agent('x', { isolation: 'worktree' })"), true);
  assert.equal(workflowRequestsWorktree("agent('x', { tier: 'medium' })"), false);
  assert.equal(commandAddsWorktree("git -C /tmp/repo worktree add -b test /tmp/wt"), true);
  assert.equal(commandAddsWorktree("git worktree list"), false);
} finally {
  rmSync(root, { recursive: true, force: true });
}

console.log("test_pi_worktree_guard: OK");
