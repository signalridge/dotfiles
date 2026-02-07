#!/usr/bin/env node
// fetch-provider-docs.js - Fetch provider documentation pages using Playwright
// Usage: node fetch-provider-docs.js [provider|all]

const { chromium } = require("playwright");

const CLAUDE_PROVIDER_DOCS = {
  deepseek: "https://api-docs.deepseek.com/guides/anthropic_api",
  kimi: "https://github.com/MoonshotAI/kimi-cli/blob/main/docs/en/configuration/providers.md",
  glm: "https://docs.bigmodel.cn/cn/guide/develop/claude",
  qwen: "https://help.aliyun.com/zh/model-studio/claude-code",
  minimax: "https://platform.minimax.io/docs/coding-plan/claude-code",
  doubao: "https://www.volcengine.com/docs/82379/1928261",
};

// Placeholder links: replace with provider-specific Codex docs later.
// Keep different from Claude links by design.
const CODEX_PROVIDER_DOCS = {
  deepseek: "TODO_CODEX_DOC_DEEPSEEK",
  kimi: "TODO_CODEX_DOC_KIMI",
  glm: "TODO_CODEX_DOC_GLM",
  qwen: "TODO_CODEX_DOC_QWEN",
  minimax: "TODO_CODEX_DOC_MINIMAX",
  doubao: "TODO_CODEX_DOC_DOUBAO",
};

function isFetchableUrl(url) {
  return typeof url === "string" && /^https?:\/\//.test(url);
}

async function fetchPage(url, timeout = 60000) {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    userAgent:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  });
  const page = await context.newPage();

  try {
    await page.goto(url, { waitUntil: "domcontentloaded", timeout });
    await page.waitForTimeout(5000);
    try {
      await page.waitForFunction(
        () => document.body && document.body.innerText.length > 1000,
        { timeout: 30000 },
      );
    } catch {
      // Continue if content-length wait times out.
    }

    const content = await page.evaluate(() => {
      const clone = document.body.cloneNode(true);
      clone
        .querySelectorAll("script, style, noscript")
        .forEach((el) => el.remove());
      return clone.innerText;
    });

    return content;
  } finally {
    await browser.close();
  }
}

async function fetchTargetDoc(provider, target, url) {
  if (!isFetchableUrl(url)) {
    return {
      url,
      note: `placeholder (${target})`,
    };
  }

  console.error(`Fetching ${target}/${provider}...`);
  try {
    const content = await fetchPage(url);
    console.error(`  ✓ ${target}/${provider}: ${content.length} chars`);
    return {
      url,
      content: content.slice(0, 15000),
    };
  } catch (error) {
    console.error(`  ✗ ${target}/${provider}: ${error.message}`);
    return {
      url,
      error: error.message,
    };
  }
}

async function main() {
  const provider = process.argv[2] || "all";
  const providers =
    provider === "all" ? Object.keys(CLAUDE_PROVIDER_DOCS) : [provider];

  const results = {};

  for (const p of providers) {
    const claudeUrl = CLAUDE_PROVIDER_DOCS[p];
    const codexUrl = CODEX_PROVIDER_DOCS[p];

    if (!claudeUrl && !codexUrl) {
      console.error(`Unknown provider: ${p}`);
      continue;
    }

    const claude = await fetchTargetDoc(p, "claude", claudeUrl);
    const codex = await fetchTargetDoc(p, "codex", codexUrl);
    results[p] = { claude, codex };
  }

  console.log(JSON.stringify(results, null, 2));
}

main().catch(console.error);
