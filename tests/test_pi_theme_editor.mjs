import assert from "node:assert/strict";
import {
  HARDWARE_CURSOR_MARKER,
  detachLeadingShellBang,
  highlightLeadingSlashToken,
  injectPromptSymbol,
  wrapWithRoundedBorder,
} from "../dot_pi/agent/extensions/pi-input-prefix/render.ts";

const identity = (text) => text;
const stripSgr = (text) => text.replaceAll(/\u001B\[[0-9;]*m/g, "");

const promptLine = "    hello         ";
const withPrompt = injectPromptSymbol(promptLine, ">");
assert.equal(withPrompt, "  > hello         ");
assert.equal(withPrompt.length, promptLine.length);
assert.equal(injectPromptSymbol("  too narrow", ">"), undefined);

const shellLine = "    !git status        ";
const detachedShell = detachLeadingShellBang(shellLine);
assert.equal(detachedShell.line, "    git status         ");
assert.equal(detachedShell.detached, true);
assert.equal(detachedShell.cursorOnPrompt, false);
assert.equal(detachedShell.line.length, shellLine.length);

const cursorShell = detachLeadingShellBang(
  `    ${HARDWARE_CURSOR_MARKER}\x1b[7m!\x1b[0mgit status        `,
);
assert.equal(cursorShell.detached, true);
assert.equal(cursorShell.cursorOnPrompt, true);
assert.equal(cursorShell.hardwareCursorMarker, HARDWARE_CURSOR_MARKER);
assert.equal(cursorShell.line, "    git status         ");

const box = wrapWithRoundedBorder(
  ["────────────────────", "    hello           ", "────────────────────"],
  identity,
);
assert.deepEqual(box, ["╭──────────────────╮", "│   hello          │", "╰──────────────────╯"]);
assert.ok(box.every((line) => line.length === 20));

const label = " \x1b[1m! shell mode\x1b[0m ";
const shellBox = wrapWithRoundedBorder(
  ["────────────────────", "                    ", "────────────────────"],
  identity,
  { label },
);
assert.equal(stripSgr(shellBox[0]), "╭ ! shell mode ────╮");
assert.equal(stripSgr(shellBox[0]).length, 20);

const magenta = (text) => `\x1b[35m${text}\x1b[39m`;
const coloredBox = wrapWithRoundedBorder(
  [magenta("─").repeat(8), "        ", magenta("─").repeat(8)],
  magenta,
);
assert.deepEqual(coloredBox.map(stripSgr), ["╭──────╮", "│      │", "╰──────╯"]);


const themedAccent = (text) => `\x1b[1m${magenta(text)}\x1b[22m`;
const slashWithCursor = `    ${HARDWARE_CURSOR_MARKER}\x1b[7m/\x1b[0mhelp       `;
const highlightedSlash = highlightLeadingSlashToken(slashWithCursor, themedAccent);
assert.notEqual(highlightedSlash, undefined);
assert.equal(
  stripSgr(highlightedSlash).replaceAll(HARDWARE_CURSOR_MARKER, ""),
  "    /help       ",
);
assert.match(highlightedSlash, /\x1b\[35m/);
assert.match(highlightedSlash, /\x1b\[1m/);
assert.equal(highlightLeadingSlashToken("    path/to/file   ", themedAccent), undefined);


console.log("test_pi_theme_following_editor: OK");
