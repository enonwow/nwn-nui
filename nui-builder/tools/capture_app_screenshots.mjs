#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { chromium } from "playwright";

const DEFAULTS = {
  url: "http://127.0.0.1:4174",
  integrationDir: "../tests/app",
  outputDir: "./artifacts/app-screenshots",
  waitMs: 180,
  timeoutMs: 10000,
  clean: true,
  headless: true,
  limit: 0,
  failOnErrors: false,
};

function parseArgs(argv) {
  const options = {
    ...DEFAULTS,
    match: [],
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    switch (arg) {
      case "--url":
        options.url = argv[++i] ?? options.url;
        break;
      case "--integration-dir":
        options.integrationDir = argv[++i] ?? options.integrationDir;
        break;
      case "--output-dir":
        options.outputDir = argv[++i] ?? options.outputDir;
        break;
      case "--wait-ms":
        options.waitMs = Math.max(0, Number(argv[++i] ?? options.waitMs) || options.waitMs);
        break;
      case "--timeout-ms":
        options.timeoutMs = Math.max(1000, Number(argv[++i] ?? options.timeoutMs) || options.timeoutMs);
        break;
      case "--limit":
        options.limit = Math.max(0, Math.trunc(Number(argv[++i] ?? "0") || 0));
        break;
      case "--match": {
        const value = (argv[++i] ?? "").trim();
        if (value) options.match.push(value.toLowerCase());
        break;
      }
      case "--clean":
        options.clean = true;
        break;
      case "--no-clean":
        options.clean = false;
        break;
      case "--headed":
        options.headless = false;
        break;
      case "--headless":
        options.headless = true;
        break;
      case "--fail-on-errors":
        options.failOnErrors = true;
        break;
      default:
        if (arg.startsWith("--")) {
          throw new Error(`Unknown option: ${arg}`);
        }
        break;
    }
  }
  return options;
}

function normalizeScenario(baseName, imageFileName) {
  const stem = path.parse(imageFileName).name;
  if (stem === baseName) return "";
  const pref = `${baseName}_`;
  if (stem.startsWith(pref)) return stem.slice(pref.length).toLowerCase();
  return stem.toLowerCase();
}

async function listFixtures(integrationDir, matchFilters) {
  const entries = await fs.readdir(integrationDir, { withFileTypes: true });
  const fixtures = [];
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (entry.name.startsWith("_")) continue;
    if (entry.name === "assets") continue;
    const folderName = entry.name;
    const folderPath = path.join(integrationDir, folderName);
    const files = await fs.readdir(folderPath, { withFileTypes: true });
    const juiFiles = files
      .filter((file) => file.isFile() && file.name.toLowerCase().endsWith(".jui"))
      .map((file) => file.name)
      .sort((a, b) => a.localeCompare(b));
    if (!juiFiles.length) continue;

    const pngFiles = files
      .filter((file) => file.isFile() && file.name.toLowerCase().endsWith(".png"))
      .map((file) => file.name)
      .sort((a, b) => a.localeCompare(b));

    for (const juiName of juiFiles) {
      const baseName = path.parse(juiName).name;
      const referenceScreens = pngFiles.filter((pngName) => {
        const stem = path.parse(pngName).name;
        return stem === baseName || stem.startsWith(`${baseName}_`);
      });
      const screenshots = referenceScreens.length ? referenceScreens : [`${baseName}.png`];
      const id = `${folderName}/${baseName}`;
      const haystack = `${folderName}/${juiName}`.toLowerCase();
      if (matchFilters.length && !matchFilters.every((needle) => haystack.includes(needle))) {
        continue;
      }
      fixtures.push({
        id,
        folderName,
        baseName,
        juiName,
        juiPath: path.join(folderPath, juiName),
        screenshots: screenshots.map((fileName) => ({
          fileName,
          scenario: normalizeScenario(baseName, fileName),
        })),
      });
    }
  }
  return fixtures.sort((a, b) => a.id.localeCompare(b.id));
}

async function ensureVisualMode(page, timeoutMs) {
  const visualButton = page.getByRole("button", { name: /^Visual$/ }).first();
  await visualButton.click();
  await page.locator(".canvas-surface.preview .nui-live-root").first().waitFor({ state: "visible", timeout: timeoutMs });
}

async function disableVisualOverlays(page) {
  const optionsTab = page.getByRole("tab", { name: "Options" }).first();
  if (await optionsTab.isVisible().catch(() => false)) {
    await optionsTab.click();
  } else {
    await page.getByRole("tab", { name: "Properties" }).first().click();
  }
  const toggles = [
    page.getByLabel("Show IDs (NuiId)").first(),
    page.getByLabel("Show Image Regions").first(),
    page.getByLabel("Show Selection Outlines").first(),
  ];
  for (const toggle of toggles) {
    if (await toggle.isVisible().catch(() => false)) {
      if (await toggle.isChecked().catch(() => false)) {
        await toggle.uncheck();
      }
    }
  }
}

async function closeNoticeToast(page) {
  const closeBtn = page.locator(".notice-toast button").first();
  if (await closeBtn.isVisible().catch(() => false)) {
    await closeBtn.click().catch(() => {});
  }
}

async function importFixture(page, fixture, timeoutMs) {
  const input = page.locator('input[type="file"][accept*=".jui"]').first();
  await input.setInputFiles(fixture.juiPath);
  await page.locator(".nui-live-window").first().waitFor({ state: "visible", timeout: timeoutMs });
}

async function count(locator) {
  try {
    return await locator.count();
  } catch {
    return 0;
  }
}

async function openFirstCombo(page) {
  const combo = page.locator(".nui-live-combo.interactive").first();
  if ((await count(combo)) === 0) return false;
  await combo.click();
  await page.waitForTimeout(40);
  return true;
}

async function setComboIndex(page, index) {
  if (!(await openFirstCombo(page))) return false;
  const items = page.locator(".nui-live-combo-item");
  const total = await count(items);
  if (total === 0) return false;
  const resolved = Math.max(0, Math.min(total - 1, index));
  await items.nth(resolved).click();
  await page.waitForTimeout(40);
  return true;
}

async function setOptionsIndex(page, index) {
  const buttons = page.locator(".nui-live-options button");
  const total = await count(buttons);
  if (total === 0) return false;
  const resolved = Math.max(0, Math.min(total - 1, index));
  await buttons.nth(resolved).click();
  await page.waitForTimeout(40);
  return true;
}

async function toggleCheck(page) {
  const check = page.locator(".nui-live-check.interactive").first();
  if ((await count(check)) === 0) return false;
  await check.click();
  await page.waitForTimeout(40);
  return true;
}

async function setSliderByPosition(page, kind) {
  const slider = page.locator(".nui-live-slider-input").first();
  if ((await count(slider)) === 0) return false;
  const min = Number((await slider.getAttribute("min")) ?? "0");
  const max = Number((await slider.getAttribute("max")) ?? "1");
  if (!Number.isFinite(min) || !Number.isFinite(max)) return false;
  const target = kind === "min" ? min : kind === "max" ? max : min + (max - min) * 0.5;
  await slider.evaluate((el, raw) => {
    const input = el;
    input.value = String(raw);
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }, target);
  await page.waitForTimeout(50);
  return true;
}

function hexToRgb(hex) {
  const compact = String(hex ?? "").trim().replace(/^#/, "");
  if (!/^[0-9a-fA-F]{6}$/.test(compact)) return null;
  return {
    r: Number.parseInt(compact.slice(0, 2), 16),
    g: Number.parseInt(compact.slice(2, 4), 16),
    b: Number.parseInt(compact.slice(4, 6), 16),
  };
}

function rgbToHsv(rgb) {
  const r = rgb.r / 255;
  const g = rgb.g / 255;
  const b = rgb.b / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const delta = max - min;
  let h = 0;
  if (delta > 0) {
    if (max === r) h = ((g - b) / delta) % 6;
    else if (max === g) h = (b - r) / delta + 2;
    else h = (r - g) / delta + 4;
    h *= 60;
    if (h < 0) h += 360;
  }
  const s = max === 0 ? 0 : delta / max;
  return { h, s, v: max };
}

async function setColorPickerColor(page, hex) {
  const rgb = hexToRgb(hex);
  if (!rgb) return false;
  const hsv = rgbToHsv(rgb);
  const sv = page.locator(".nui-live-colorpicker-native-sv").first();
  const hue = page.locator(".nui-live-colorpicker-native-hue").first();
  if ((await count(sv)) === 0 || (await count(hue)) === 0) return false;
  const hueBox = await hue.boundingBox();
  const svBox = await sv.boundingBox();
  if (!hueBox || !svBox) return false;
  const hueRatio = Math.max(0, Math.min(1, hsv.h / 360));
  const satRatio = Math.max(0, Math.min(1, hsv.s));
  const valRatio = Math.max(0, Math.min(1, hsv.v));
  await page.mouse.click(
    hueBox.x + hueBox.width * 0.5,
    hueBox.y + hueBox.height * hueRatio,
  );
  await page.waitForTimeout(40);
  await page.mouse.click(
    svBox.x + svBox.width * satRatio,
    svBox.y + svBox.height * (1 - valRatio),
  );
  await page.waitForTimeout(80);
  return true;
}

async function hoverPrimaryTarget(page) {
  const candidates = [
    page.locator(".nui-live-drawlist-host").first(),
    page.locator(".nui-live-combo.interactive").first(),
    page.locator(".nui-live-button").first(),
    page.locator(".nui-live-options button").first(),
  ];
  for (const target of candidates) {
    if ((await count(target)) > 0) {
      await target.hover();
      await page.waitForTimeout(60);
      return true;
    }
  }
  return false;
}

async function pressPrimaryTarget(page) {
  const candidates = [
    page.locator(".nui-live-drawlist-host").first(),
    page.locator(".nui-live-button").first(),
    page.locator(".nui-live-combo.interactive").first(),
  ];
  for (const target of candidates) {
    if ((await count(target)) > 0) {
      const box = await target.boundingBox();
      if (!box) continue;
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
      await page.mouse.down();
      await page.waitForTimeout(70);
      await page.mouse.up();
      return true;
    }
  }
  return false;
}

function letterToIndex(letter) {
  const map = { a: 0, b: 1, c: 2 };
  return map[letter] ?? 0;
}

async function applyScenario(page, scenario) {
  if (!scenario) return ["default"];
  const notes = [];
  const lower = scenario.toLowerCase();

  const letterMatch = lower.match(/(?:selected|tab)_([abc])/);
  if (letterMatch) {
    const idx = letterToIndex(letterMatch[1]);
    if (await setOptionsIndex(page, idx)) notes.push(`options:${idx}`);
    else if (await setComboIndex(page, idx)) notes.push(`combo:${idx}`);
  }

  const numericSelMatch = lower.match(/sel_(\d+)/);
  if (numericSelMatch) {
    const raw = Math.max(1, Number(numericSelMatch[1]));
    const idx = raw - 1;
    if (await setOptionsIndex(page, idx)) notes.push(`options:${idx}`);
    else if (await setComboIndex(page, idx)) notes.push(`combo:${idx}`);
  }

  if (lower.includes("open")) {
    if (await openFirstCombo(page)) notes.push("combo:open");
  }

  if (lower.includes("checked") || lower.includes("enabled")) {
    if (await toggleCheck(page)) notes.push("check:toggle");
  }

  if (lower.includes("min")) {
    if (await setSliderByPosition(page, "min")) notes.push("slider:min");
  } else if (lower.includes("max")) {
    if (await setSliderByPosition(page, "max")) notes.push("slider:max");
  } else if (lower.includes("mid")) {
    if (await setSliderByPosition(page, "mid")) notes.push("slider:mid");
  }

  if (lower.includes("changed")) {
    if (await setColorPickerColor(page, "#c2be2a")) notes.push("color:changed");
  }

  if (lower.includes("hover")) {
    if (await hoverPrimaryTarget(page)) notes.push("hover");
  }
  if (lower.includes("pressed") || lower.includes("click")) {
    if (await pressPrimaryTarget(page)) notes.push("press");
  }

  if (!notes.length) notes.push("default");
  return notes;
}

async function captureWindow(page, outputPath, timeoutMs) {
  const liveWindow = page.locator(".nui-live-window").first();
  if ((await count(liveWindow)) > 0) {
    await liveWindow.waitFor({ state: "visible", timeout: timeoutMs });
    await liveWindow.screenshot({ animations: "disabled", path: outputPath });
    return "window";
  }
  const liveRoot = page.locator(".nui-live-root").first();
  await liveRoot.waitFor({ state: "visible", timeout: timeoutMs });
  await liveRoot.screenshot({ animations: "disabled", path: outputPath });
  return "root";
}

async function readPngDimensions(filePath) {
  const buffer = await fs.readFile(filePath);
  if (buffer.length < 24) return null;
  // PNG signature
  if (
    buffer[0] !== 0x89 ||
    buffer[1] !== 0x50 ||
    buffer[2] !== 0x4e ||
    buffer[3] !== 0x47 ||
    buffer[4] !== 0x0d ||
    buffer[5] !== 0x0a ||
    buffer[6] !== 0x1a ||
    buffer[7] !== 0x0a
  ) {
    return null;
  }
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
  };
}

function centeredClip(box, target, viewport) {
  const targetW = Math.max(1, Math.round(target.width));
  const targetH = Math.max(1, Math.round(target.height));
  const vpW = Math.max(1, Math.round(viewport.width));
  const vpH = Math.max(1, Math.round(viewport.height));
  const width = Math.min(targetW, vpW);
  const height = Math.min(targetH, vpH);
  let x = Math.round(box.x + (box.width - width) / 2);
  let y = Math.round(box.y + (box.height - height) / 2);
  x = Math.max(0, Math.min(vpW - width, x));
  y = Math.max(0, Math.min(vpH - height, y));
  return { x, y, width, height };
}

async function captureWindowSized(page, outputPath, timeoutMs, referenceSize) {
  const liveWindow = page.locator(".nui-live-window").first();
  if ((await count(liveWindow)) > 0) {
    await liveWindow.waitFor({ state: "visible", timeout: timeoutMs });
    if (referenceSize?.width && referenceSize?.height) {
      const box = await liveWindow.boundingBox();
      const viewport = page.viewportSize() ?? { width: 1920, height: 1080 };
      if (box) {
        const clip = centeredClip(box, referenceSize, viewport);
        await page.screenshot({ animations: "disabled", clip, path: outputPath });
        return "window";
      }
    }
    await liveWindow.screenshot({ animations: "disabled", path: outputPath });
    return "window";
  }
  const liveRoot = page.locator(".nui-live-root").first();
  await liveRoot.waitFor({ state: "visible", timeout: timeoutMs });
  if (referenceSize?.width && referenceSize?.height) {
    const box = await liveRoot.boundingBox();
    const viewport = page.viewportSize() ?? { width: 1920, height: 1080 };
    if (box) {
      const clip = centeredClip(box, referenceSize, viewport);
      await page.screenshot({ animations: "disabled", clip, path: outputPath });
      return "root";
    }
  }
  await liveRoot.screenshot({ animations: "disabled", path: outputPath });
  return "root";
}

async function launchBrowser(headless) {
  const errors = [];
  try {
    return await chromium.launch({ headless, channel: "msedge" });
  } catch (error) {
    errors.push(`msedge channel failed: ${error instanceof Error ? error.message : String(error)}`);
  }
  try {
    return await chromium.launch({ headless });
  } catch (error) {
    errors.push(`chromium fallback failed: ${error instanceof Error ? error.message : String(error)}`);
  }
  throw new Error(
    `Could not launch a browser for capture.\n${errors.join("\n")}\nHint: install browser runtime with "npx playwright install chromium".`,
  );
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const cwd = (process.env.INIT_CWD && process.env.INIT_CWD.trim()) || process.cwd();
  const integrationDir = path.resolve(cwd, options.integrationDir);
  const outputDir = path.resolve(cwd, options.outputDir);

  const fixtures = await listFixtures(integrationDir, options.match);
  const limitedFixtures = options.limit > 0 ? fixtures.slice(0, options.limit) : fixtures;
  if (!limitedFixtures.length) {
    throw new Error(`No fixtures found in ${integrationDir}.`);
  }

  if (options.clean) {
    await fs.rm(outputDir, { recursive: true, force: true });
  }
  await fs.mkdir(outputDir, { recursive: true });

  const browser = await launchBrowser(options.headless);
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

  const captureRows = [];
  const startedAt = new Date().toISOString();
  let failures = 0;

  try {
    await page.goto(options.url, { waitUntil: "load", timeout: options.timeoutMs });
    await page.getByRole("button", { name: "Import Project" }).first().waitFor({ state: "visible", timeout: options.timeoutMs });
    await ensureVisualMode(page, options.timeoutMs);
    await disableVisualOverlays(page);

    for (const fixture of limitedFixtures) {
      for (const screenshot of fixture.screenshots) {
        const outputPath = path.join(outputDir, fixture.folderName, screenshot.fileName);
        const referencePath = path.join(integrationDir, fixture.folderName, screenshot.fileName);
        await fs.mkdir(path.dirname(outputPath), { recursive: true });

        const row = {
          fixture: fixture.id,
          juiFile: path.relative(cwd, fixture.juiPath),
          reference: path.relative(cwd, referencePath),
          output: path.relative(cwd, outputPath),
          scenario: screenshot.scenario || "default",
          status: "ok",
          mode: "window",
          actions: [],
          error: "",
        };
        try {
          const referenceSize = await readPngDimensions(referencePath).catch(() => null);
          await importFixture(page, fixture, options.timeoutMs);
          await ensureVisualMode(page, options.timeoutMs);
          const actions = await applyScenario(page, screenshot.scenario);
          row.actions = actions;
          await page.waitForTimeout(options.waitMs);
          row.mode = await captureWindowSized(page, outputPath, options.timeoutMs, referenceSize);
          await closeNoticeToast(page);
        } catch (error) {
          failures += 1;
          row.status = "error";
          row.error = error instanceof Error ? error.message : String(error);
        }
        captureRows.push(row);
      }
    }
  } finally {
    await page.close().catch(() => {});
    await browser.close().catch(() => {});
  }

  const finishedAt = new Date().toISOString();
  const summary = {
    startedAt,
    finishedAt,
    url: options.url,
    integrationDir,
    outputDir,
    fixtureCount: limitedFixtures.length,
    screenshotCount: captureRows.length,
    failures,
    rows: captureRows,
  };
  const summaryPath = path.join(outputDir, "capture-summary.json");
  await fs.writeFile(summaryPath, JSON.stringify(summary, null, 2), "utf8");

  const okCount = captureRows.length - failures;
  console.log(`Captured screenshots: ${okCount}/${captureRows.length}`);
  console.log(`Capture summary: ${summaryPath}`);

  if (captureRows.length === 0) {
    process.exitCode = 2;
  } else if (failures > 0 && options.failOnErrors) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
