#!/usr/bin/env node
// Captures the V8 states of the V3 screen handoff from the artifact
// "MemoX — Mobile UI Kit v3" as light and dark PNGs.
//
//   node tools/design/capture_screens.mjs --html <artifact.html> [--out <dir>]
//        [--manifest <file>] [--only 01,07]
//
// Get the HTML with the Artifact tool (action "read"); it saves the page to a file.
import { createRequire } from 'node:module';
import { execSync } from 'node:child_process';
import { mkdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { parseArgs } from 'node:util';
import {
  parseStepLabel,
  frameTheme,
  imagePath,
  validateManifest,
  missingStates,
} from './capture_lib.mjs';

const USAGE =
  'Usage: node tools/design/capture_screens.mjs --html <artifact.html> ' +
  '[--out <dir>] [--manifest <file>] [--only 01,07]';
const ROW_TIMEOUT_MS = 15000;
const SETTLE_MS = 400;

function loadPlaywright() {
  const globalRoot = execSync('npm root -g').toString().trim();
  const require = createRequire(import.meta.url);
  return require(path.join(globalRoot, 'playwright'));
}

async function waitForLabelChange(page, label, previous) {
  const handle = await label.elementHandle();
  await page.waitForFunction(
    ([element, text]) => element.textContent !== text,
    [handle, previous],
  );
}

async function captureScreen(page, screen, outDir) {
  const row = page
    .locator('.row')
    .filter({ has: page.locator('.row-num', { hasText: new RegExp(`^${screen.num}$`) }) });
  await row.scrollIntoViewIfNeeded();
  try {
    await row.locator('.phone').first().waitFor({ timeout: ROW_TIMEOUT_MS });
  } catch {
    throw new Error(`Screen ${screen.num}: no phone frame rendered within ${ROW_TIMEOUT_MS} ms`);
  }
  const label = row.locator('.st-label');
  const previousButton = row.getByRole('button', { name: 'Previous state' });
  const nextButton = row.getByRole('button', { name: 'Next state' });

  // Rewind to state 1, bounded whether or not the stepper wraps.
  let step = parseStepLabel(await label.textContent());
  for (let i = 0; i < step.total && step.index !== 1; i++) {
    const before = await label.textContent();
    await previousButton.click();
    await waitForLabelChange(page, label, before);
    step = parseStepLabel(await label.textContent());
  }

  const wanted = new Map(screen.states.map((state) => [state.label, state.id]));
  const seen = new Set();
  for (let i = 0; i < step.total; i++) {
    const current = parseStepLabel(await label.textContent());
    seen.add(current.label);
    const stateId = wanted.get(current.label);
    if (stateId) {
      await page.waitForTimeout(SETTLE_MS);
      for (const frame of await row.locator('.frame-wrap').all()) {
        const theme = frameTheme(await frame.locator('.theme-label').textContent());
        const file = imagePath(outDir, screen.dir, stateId, theme);
        mkdirSync(path.dirname(file), { recursive: true });
        await frame.locator('.phone').screenshot({ path: file, animations: 'disabled' });
        console.log(`captured ${file}`);
      }
    }
    if (i < step.total - 1) {
      const before = await label.textContent();
      await nextButton.click();
      await waitForLabelChange(page, label, before);
    }
  }
  return missingStates(screen, seen);
}

async function main() {
  const { values } = parseArgs({
    options: {
      html: { type: 'string' },
      out: { type: 'string', default: 'docs/shared/ui/design-handoff/screens/img' },
      manifest: { type: 'string', default: 'tools/design/screen_states.json' },
      only: { type: 'string' },
    },
  });
  if (!values.html) {
    console.error(USAGE);
    return 2;
  }
  const only = values.only ? values.only.split(',').map((num) => num.trim()) : null;
  const screens = validateManifest(JSON.parse(readFileSync(values.manifest, 'utf8'))).filter(
    (screen) => !only || only.includes(screen.num),
  );

  const { chromium } = loadPlaywright();
  const browser = await chromium.launch();
  let failed = false;
  try {
    const page = await browser.newPage({
      viewport: { width: 1600, height: 1100 },
      deviceScaleFactor: 1,
    });
    await page.goto(pathToFileURL(path.resolve(values.html)).href);
    await page.waitForSelector('.gallery .row', { timeout: 30000 });
    await page.getByRole('button', { name: 'Both', exact: true }).click();
    await page.getByRole('button', { name: '390', exact: true }).click();
    for (const screen of screens) {
      const missing = await captureScreen(page, screen, values.out);
      if (missing.length > 0) {
        console.error(`Screen ${screen.num}: states not found in the artifact: ${missing.join(', ')}`);
        failed = true;
      }
    }
  } finally {
    await browser.close();
  }
  return failed ? 1 : 0;
}

main().then(
  (code) => process.exit(code),
  (error) => {
    console.error(`error: ${error.message}`);
    process.exit(1);
  },
);
