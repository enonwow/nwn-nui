#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import { chromium } from 'playwright';

const url = process.argv[2] || 'http://127.0.0.1:5180';
const testQuery = process.argv[3] || 'nuiduelui_duel_swaplayout';
const outPath = process.argv[4] || './artifacts/duel-capture-loaded/nuiduelui_duel_swaplayout_loaded.png';

async function main() {
  const browser = await chromium.launch({ headless: true, channel: 'msedge' }).catch(async () => chromium.launch({ headless: true }));
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  try {
    page.on('dialog', async (dialog) => {
      try {
        await dialog.accept();
      } catch {
        // ignore
      }
    });

    await page.goto(url, { waitUntil: 'load', timeout: 20000 });

    // palette tab: Test
    await page.getByRole('button', { name: /^Test$/ }).first().click();

    // search in palette search input
    const search = page.locator('.palette-header input.search-input').first();
    await search.fill(testQuery);

    // click Load Test for a specific card (by visible template id/name)
    const cardsInTestMode = page.locator('article.palette-template-item');
    const cardTotal = await cardsInTestMode.count();
    console.log(`cards visible in Test mode: ${cardTotal}`);
    const card = page.locator('article.palette-template-item', { hasText: testQuery }).first();
    const cardCount = await card.count();
    console.log(`cards matching '${testQuery}': ${cardCount}`);
    await page.screenshot({ path: path.resolve('./artifacts/duel-capture-loaded/_debug_test_mode.png') });
    if (cardCount > 0) {
      await card.getByRole('button', { name: 'Load Test' }).click();
    } else {
      // No exact match with active filter. Clear search and load first available test card.
      await search.fill('');
      await page.waitForTimeout(120);
      const fallbackCard = page.locator('article.palette-template-item').first();
      await fallbackCard.getByRole('button', { name: 'Load Test' }).click();
    }

    // switch to Visual preview
    await page.getByRole('button', { name: /^Visual$/ }).first().click();

    // disable overlays from Options
    await page.getByRole('tab', { name: 'Options' }).first().click();
    for (const label of ['Show IDs (NuiId)', 'Show Image Regions', 'Show Selection Outlines']) {
      const cb = page.getByLabel(label).first();
      if (await cb.isVisible().catch(() => false)) {
        if (await cb.isChecked().catch(() => false)) await cb.uncheck();
      }
    }

    // wait for render
    await page.waitForTimeout(900);

    const win = page.locator('.nui-live-window').first();
    await win.waitFor({ state: 'visible', timeout: 15000 });

    await fs.mkdir(path.dirname(path.resolve(outPath)), { recursive: true });
    await win.screenshot({ path: path.resolve(outPath), animations: 'disabled' });
    console.log(`Saved: ${path.resolve(outPath)}`);
  } finally {
    await page.close().catch(() => {});
    await browser.close().catch(() => {});
  }
}

main().catch((err) => {
  console.error(err?.message || String(err));
  process.exit(1);
});
