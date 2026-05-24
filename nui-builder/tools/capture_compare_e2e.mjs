#!/usr/bin/env node
import fs from "node:fs";
import { spawn, spawnSync } from "node:child_process";
import path from "node:path";
import process from "node:process";

const DEFAULTS = {
  host: "127.0.0.1",
  port: 4174,
  integrationDir: "../tests/app",
  screensDir: "./artifacts/app-screenshots",
  compareDir: "./artifacts/aurora-compare",
  minSimilarity: 97,
  timeoutMs: 120000,
  headless: true,
  strict: false,
  limit: 0,
};

function parseArgs(argv) {
  const options = {
    ...DEFAULTS,
    match: [],
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    switch (arg) {
      case "--host":
        options.host = argv[++i] ?? options.host;
        break;
      case "--port":
        options.port = Math.max(1, Number(argv[++i] ?? options.port) || options.port);
        break;
      case "--integration-dir":
        options.integrationDir = argv[++i] ?? options.integrationDir;
        break;
      case "--screens-dir":
        options.screensDir = argv[++i] ?? options.screensDir;
        break;
      case "--compare-dir":
        options.compareDir = argv[++i] ?? options.compareDir;
        break;
      case "--min-similarity":
        options.minSimilarity = Number(argv[++i] ?? options.minSimilarity) || options.minSimilarity;
        break;
      case "--timeout-ms":
        options.timeoutMs = Math.max(10000, Number(argv[++i] ?? options.timeoutMs) || options.timeoutMs);
        break;
      case "--match": {
        const value = (argv[++i] ?? "").trim();
        if (value) options.match.push(value);
        break;
      }
      case "--limit":
        options.limit = Math.max(0, Math.trunc(Number(argv[++i] ?? "0") || 0));
        break;
      case "--headed":
        options.headless = false;
        break;
      case "--headless":
        options.headless = true;
        break;
      case "--strict":
        options.strict = true;
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

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function waitForServer(url, timeoutMs) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const response = await fetch(url, { method: "GET" });
      if (response.ok) return;
    } catch {
      // retry
    }
    await sleep(350);
  }
  throw new Error(`Dev server not ready at ${url} within ${timeoutMs}ms.`);
}

function run(command, args, cwd) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { cwd, stdio: "inherit", shell: false });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`Command failed (${command} ${args.join(" ")}), exit=${code}`));
    });
  });
}

function resolvePythonExecutable() {
  const envOverride = process.env.NUI_BUILDER_PYTHON;
  if (envOverride && fs.existsSync(envOverride)) {
    return envOverride;
  }
  const userProfile = process.env.USERPROFILE || "";
  const bundledPython = userProfile
    ? path.join(
        userProfile,
        ".cache",
        "codex-runtimes",
        "codex-primary-runtime",
        "dependencies",
        "python",
        "python.exe",
      )
    : "";
  if (bundledPython && fs.existsSync(bundledPython)) {
    return bundledPython;
  }
  return "python";
}

function killTree(processRef) {
  if (!processRef || processRef.killed || processRef.exitCode !== null) return;
  if (process.platform === "win32") {
    const result = spawnSync("taskkill", ["/pid", String(processRef.pid), "/t", "/f"], { stdio: "ignore" });
    if (result.status !== 0) {
      processRef.kill("SIGKILL");
    }
  } else {
    processRef.kill("SIGTERM");
  }
}

function waitForExit(processRef, timeoutMs) {
  return new Promise((resolve) => {
    if (!processRef || processRef.exitCode !== null) {
      resolve();
      return;
    }
    const timeout = setTimeout(() => {
      resolve();
    }, timeoutMs);
    processRef.once("exit", () => {
      clearTimeout(timeout);
      resolve();
    });
  });
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const cwd = (process.env.INIT_CWD && process.env.INIT_CWD.trim()) || process.cwd();
  const url = `http://${options.host}:${options.port}`;
  const integrationDir = path.resolve(cwd, options.integrationDir);
  const screensDir = path.resolve(cwd, options.screensDir);
  const compareDir = path.resolve(cwd, options.compareDir);

  console.log(`Starting Vite dev server on ${url} ...`);
  const viteCli = path.join(cwd, "node_modules", "vite", "bin", "vite.js");
  const devProcess = spawn(
    process.execPath,
    [viteCli, "--host", options.host, "--port", String(options.port), "--strictPort"],
    { cwd, stdio: ["ignore", "pipe", "pipe"], shell: false },
  );
  devProcess.stdout?.on("data", (chunk) => process.stdout.write(chunk));
  devProcess.stderr?.on("data", (chunk) => process.stderr.write(chunk));

  try {
    await waitForServer(url, options.timeoutMs);
    console.log("Server ready. Running automated capture...");
    const captureArgs = [
      "tools/capture_app_screenshots.mjs",
      "--url",
      url,
      "--integration-dir",
      integrationDir,
      "--output-dir",
      screensDir,
      "--clean",
      "--wait-ms",
      "180",
      "--timeout-ms",
      String(Math.max(10000, options.timeoutMs / 2)),
    ];
    if (!options.headless) captureArgs.push("--headed");
    if (options.limit > 0) {
      captureArgs.push("--limit", String(options.limit));
    }
    for (const match of options.match) {
      captureArgs.push("--match", match);
    }
    await run(process.execPath, captureArgs, cwd);

    console.log("Capture done. Running set comparison...");
    const compareArgs = [
      "tools/compare_screenshot_sets.py",
      "--reference-dir",
      integrationDir,
      "--candidate-dir",
      screensDir,
      "--output-dir",
      compareDir,
      "--min-similarity",
      String(options.minSimilarity),
      "--normalize-size",
      "reference",
      "--match-mode",
      "relative",
    ];
    if (options.strict) compareArgs.push("--fail-on-regressions");
    await run(resolvePythonExecutable(), compareArgs, cwd);
    console.log("Done. End-to-end capture + compare complete.");
  } finally {
    killTree(devProcess);
    await waitForExit(devProcess, 3000);
    killTree(devProcess);
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
