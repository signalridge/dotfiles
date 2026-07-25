import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import {
  HARDWARE_CURSOR_MARKER,
  KIMI_DARK_EDITOR_RGB,
  ansiRgb,
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

assert.deepEqual(KIMI_DARK_EDITOR_RGB, {
  border: [90, 90, 90],
  primary: [79, 168, 255],
  muted: [107, 107, 107],
  shell: [189, 147, 249],
});

const kimiPrimary = ansiRgb(...KIMI_DARK_EDITOR_RGB.primary, { bold: true });
const slashWithCursor = `    ${HARDWARE_CURSOR_MARKER}\x1b[7m/\x1b[0mhelp       `;
const highlightedSlash = highlightLeadingSlashToken(slashWithCursor, kimiPrimary);
assert.notEqual(highlightedSlash, undefined);
assert.equal(
  stripSgr(highlightedSlash).replaceAll(HARDWARE_CURSOR_MARKER, ""),
  "    /help       ",
);
assert.match(highlightedSlash, /\x1b\[38;2;79;168;255m/);
assert.match(highlightedSlash, /\x1b\[1m/);
assert.equal(highlightLeadingSlashToken("    path/to/file   ", kimiPrimary), undefined);
assert.throws(() => ansiRgb(256, 0, 0), RangeError);

const softTheme = JSON.parse(
  await readFile(
    new URL("../dot_pi/agent/themes/catppuccin-mocha.json", import.meta.url),
    "utf8",
  ),
);
assert.equal(softTheme.vars.draculaBorder, "#6272a4");
assert.equal(softTheme.vars.draculaFocus, "#8be9fd");
assert.equal(softTheme.vars.draculaShell, "#bd93f9");
assert.equal(softTheme.colors.border, "draculaBorder");
assert.equal(softTheme.colors.borderAccent, "draculaFocus");
assert.equal(softTheme.colors.bashMode, "draculaShell");

const vividTheme = JSON.parse(
  await readFile(
    new URL("../dot_pi/agent/themes/signalridge-dracula.json", import.meta.url),
    "utf8",
  ),
);
assert.equal(vividTheme.colors.accent, "cyan");
assert.equal(vividTheme.colors.border, "comment");
assert.equal(vividTheme.colors.borderAccent, "cyan");
assert.equal(vividTheme.colors.warning, "orange");
assert.equal(vividTheme.colors.mdCode, "cyan");
assert.equal(vividTheme.colors.mdCodeBlock, "fg");
assert.equal(vividTheme.colors.borderMuted, "currentLine");
assert.equal(vividTheme.colors.thinkingMedium, "#4fa8ff");
assert.equal(vividTheme.colors.thinkingMax, "pink");
assert.equal(vividTheme.colors.bashMode, "purple");

const piData = await readFile(new URL("../.chezmoidata/pi.yaml", import.meta.url), "utf8");
assert.match(piData, /^\s{4}theme: signalridge-dracula$/m);

const historyExtension = await readFile(
  new URL("../dot_pi/agent/extensions/pi-input-history/index.ts", import.meta.url),
  "utf8",
);
assert.match(historyExtension, /pi\.on\("session_start", \(_event, ctx\) => \{/);
assert.doesNotMatch(historyExtension, /pi\.on\("session_start", async/);

console.log("test_pi_kimi_editor: OK");
