#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const MAX_RESREF_LENGTH = 16;
const RESTYPE_BY_EXT = new Map([
  ["nss", 2009],
  ["jui", 2083],
]);

function parseArgs(argv) {
  const options = {
    sourceRoot: "",
    outputHak: "",
    dryRun: false,
  };
  for (let idx = 0; idx < argv.length; idx += 1) {
    const token = argv[idx];
    switch (token) {
      case "--source-root":
        options.sourceRoot = argv[++idx] ?? "";
        break;
      case "--output-hak":
        options.outputHak = argv[++idx] ?? "";
        break;
      case "--dry-run":
        options.dryRun = true;
        break;
      default:
        if (token.startsWith("--")) {
          throw new Error(`Unknown option: ${token}`);
        }
        break;
    }
  }
  if (!options.sourceRoot) throw new Error("Missing --source-root");
  if (!options.outputHak) throw new Error("Missing --output-hak");
  return options;
}

function isValidResref(value) {
  return /^[A-Za-z0-9_]+$/.test(value);
}

function walkFiles(rootDir) {
  const out = [];
  const stack = [rootDir];
  while (stack.length) {
    const current = stack.pop();
    if (!current) continue;
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        if (entry.name === "_tools") continue;
        stack.push(fullPath);
      } else if (entry.isFile()) {
        out.push(fullPath);
      }
    }
  }
  return out;
}

function toHakBuffer(entries) {
  const headerSize = 160;
  const keyEntrySize = 24;
  const resourceEntrySize = 8;
  const keyTableSize = entries.length * keyEntrySize;
  const resourceTableSize = entries.length * resourceEntrySize;
  const dataSize = entries.reduce((sum, item) => sum + item.bytes.length, 0);

  const buffer = Buffer.alloc(headerSize + keyTableSize + resourceTableSize + dataSize, 0);
  const keyOffset = headerSize;
  const resourceOffset = keyOffset + keyTableSize;
  const dataOffsetStart = resourceOffset + resourceTableSize;

  buffer.write("HAK ", 0, 4, "ascii");
  buffer.write("V1.0", 4, 4, "ascii");

  const now = new Date();
  const startOfYear = new Date(now.getFullYear(), 0, 1);
  const dayOfYear = Math.floor((now.getTime() - startOfYear.getTime()) / 86400000);

  buffer.writeUInt32LE(0, 8); // localizedstrings_count
  buffer.writeUInt32LE(0, 12); // localizedstrings_size
  buffer.writeUInt32LE(entries.length, 16); // keys_count
  buffer.writeUInt32LE(headerSize, 20); // localizedstrings_offset
  buffer.writeUInt32LE(keyOffset, 24); // keys_offset
  buffer.writeUInt32LE(resourceOffset, 28); // resources_offset
  buffer.writeUInt32LE(now.getFullYear() - 1900, 32); // build_year
  buffer.writeUInt32LE(dayOfYear, 36); // build_day
  buffer.writeUInt32LE(0, 40); // file_description_strref

  let dataOffset = dataOffsetStart;
  for (let idx = 0; idx < entries.length; idx += 1) {
    const entry = entries[idx];
    const keyEntryOffset = keyOffset + idx * keyEntrySize;
    const resrefBytes = Buffer.from(entry.resref, "ascii");
    resrefBytes.copy(buffer, keyEntryOffset, 0, Math.min(16, resrefBytes.length));

    buffer.writeUInt32LE(idx, keyEntryOffset + 16);
    buffer.writeUInt16LE(entry.resourceType, keyEntryOffset + 20);
    buffer.writeUInt16LE(0, keyEntryOffset + 22);

    const resourceEntryOffset = resourceOffset + idx * resourceEntrySize;
    buffer.writeUInt32LE(dataOffset, resourceEntryOffset);
    buffer.writeUInt32LE(entry.bytes.length, resourceEntryOffset + 4);

    entry.bytes.copy(buffer, dataOffset);
    dataOffset += entry.bytes.length;
  }

  return buffer;
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  const sourceRoot = path.resolve(options.sourceRoot);
  const outputHak = path.resolve(options.outputHak);
  if (!fs.existsSync(sourceRoot)) throw new Error(`Source root not found: ${sourceRoot}`);

  const discovered = walkFiles(sourceRoot);
  const entries = [];
  const errors = [];
  const seen = new Set();

  for (const filePath of discovered) {
    const ext = path.extname(filePath).toLowerCase().replace(/^\./, "");
    if (!RESTYPE_BY_EXT.has(ext)) continue;
    const baseName = path.basename(filePath, path.extname(filePath));
    const resref = baseName.toLowerCase();
    const relPath = path.relative(sourceRoot, filePath).replace(/\\/g, "/");
    if (resref.length > MAX_RESREF_LENGTH) {
      errors.push(`${relPath}: resref '${resref}' exceeds ${MAX_RESREF_LENGTH} chars`);
      continue;
    }
    if (!isValidResref(resref)) {
      errors.push(`${relPath}: invalid resref '${resref}' (allowed: A-Z, 0-9, _)`);
      continue;
    }
    const resourceType = RESTYPE_BY_EXT.get(ext);
    const dedupeKey = `${resref}:${resourceType}`;
    if (seen.has(dedupeKey)) {
      errors.push(`${relPath}: duplicate resref+type '${dedupeKey}'`);
      continue;
    }
    seen.add(dedupeKey);
    entries.push({
      filePath,
      relPath,
      ext,
      resref,
      resourceType,
      bytes: fs.readFileSync(filePath),
    });
  }

  if (errors.length) {
    throw new Error(`Validation failed:\n- ${errors.join("\n- ")}`);
  }
  if (!entries.length) {
    throw new Error("No .nss/.jui files found to pack.");
  }

  entries.sort((a, b) => {
    if (a.resref === b.resref) return a.resourceType - b.resourceType;
    return a.resref.localeCompare(b.resref);
  });

  const totalBytes = entries.reduce((sum, item) => sum + item.bytes.length, 0);
  if (options.dryRun) {
    console.log(`DRY RUN: ${entries.length} resources ready for ${outputHak}`);
    console.log(`Total payload bytes: ${totalBytes}`);
    for (const entry of entries) {
      console.log(`- ${entry.relPath} -> ${entry.resref} (type=${entry.resourceType})`);
    }
    return;
  }

  const hakBuffer = toHakBuffer(entries);
  fs.mkdirSync(path.dirname(outputHak), { recursive: true });

  const deadlineMs = Date.now() + 30000;
  let lastError = null;
  while (Date.now() < deadlineMs) {
    try {
      fs.writeFileSync(outputHak, hakBuffer);
      console.log(`Packed ${entries.length} resources into ${outputHak}`);
      console.log(`Payload bytes: ${totalBytes}`);
      return;
    } catch (error) {
      const code = error && typeof error === "object" && "code" in error ? error.code : "";
      if (code === "EBUSY" || code === "EACCES" || code === "EPERM") {
        lastError = error;
        Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 500);
        continue;
      }
      throw error;
    }
  }

  const message =
    lastError && typeof lastError === "object" && "message" in lastError
      ? String(lastError.message)
      : "unknown lock error";
  throw new Error(`Could not replace target HAK within 30s: ${outputHak}\nLast error: ${message}`);
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
