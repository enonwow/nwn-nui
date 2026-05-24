import { readdirSync, readFileSync } from "fs";
import { dirname, extname, relative, resolve } from "path";
import { fileURLToPath } from "url";
import { describe, expect, it } from "vitest";

const thisDir = dirname(fileURLToPath(import.meta.url));
const workspaceRoot = resolve(thisDir, "../../..");
const demoDir = resolve(thisDir, "../demo");
const customDir = resolve(thisDir, "../custom-components");
const integrationAppDir = resolve(thisDir, "../../../tests/app");

const FLAG_KEYS = ["resizable", "collapsed", "closable", "transparent", "border", "accepts_input"];

function stripBom(value) {
  if (!value) return value;
  return value.charCodeAt(0) === 0xfeff ? value.slice(1) : value;
}

function walkFiles(dir, allowedExt, out = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const fullPath = resolve(dir, entry.name);
    if (entry.isDirectory()) {
      walkFiles(fullPath, allowedExt, out);
      continue;
    }
    if (entry.isFile() && allowedExt.has(extname(entry.name).toLowerCase())) {
      out.push(fullPath);
    }
  }
  return out;
}

function loadJson(filePath) {
  const raw = stripBom(readFileSync(filePath, "utf8"));
  return JSON.parse(raw);
}

function toRelPath(filePath) {
  return relative(workspaceRoot, filePath).replace(/\\/g, "/");
}

function getJuiPayload(data) {
  if (data && typeof data === "object" && data.jui && typeof data.jui === "object") {
    return data.jui;
  }
  return data;
}

function collectNodeIssues(rootNode) {
  const issues = [];
  const visit = (node) => {
    if (Array.isArray(node)) {
      node.forEach(visit);
      return;
    }
    if (!node || typeof node !== "object") return;

    if (typeof node.type !== "string" || !node.type.trim()) {
      issues.push("node.type missing");
    }
    if (Object.prototype.hasOwnProperty.call(node, "children") && !Array.isArray(node.children)) {
      issues.push("node.children must be array when present");
    }
    if (Object.prototype.hasOwnProperty.call(node, "row_template") && !Array.isArray(node.row_template)) {
      issues.push("node.row_template must be array when present");
    }
    if (Object.prototype.hasOwnProperty.call(node, "swap_views") && !Array.isArray(node.swap_views)) {
      issues.push("node.swap_views must be array when present");
    }

    if (Array.isArray(node.children)) node.children.forEach(visit);
    if (Array.isArray(node.swap_views)) node.swap_views.forEach(visit);
    if (Array.isArray(node.row_template)) {
      node.row_template.forEach((cell) => {
        if (Array.isArray(cell) && cell[0]) visit(cell[0]);
      });
    }
  };
  visit(rootNode);
  return issues;
}

function hasValidGeometry(payload) {
  if (!payload || typeof payload !== "object") return false;
  const geometry = payload.geometry;
  if (!geometry || typeof geometry !== "object") return false;
  if (typeof geometry.bind === "string" && geometry.bind.length > 0) return true;
  return ["x", "y", "w", "h"].every((key) => typeof geometry[key] === "number" && Number.isFinite(geometry[key]));
}

function flagTypeIssues(payload) {
  const issues = [];
  for (const key of FLAG_KEYS) {
    if (!Object.prototype.hasOwnProperty.call(payload, key)) continue;
    const value = payload[key];
    const isBindObject = value && typeof value === "object" && typeof value.bind === "string" && value.bind.length > 0;
    if (typeof value !== "boolean" && !isBindObject) {
      issues.push(`${key} must be boolean`);
    }
  }
  return issues;
}

const demoEntries = walkFiles(demoDir, new Set([".json"]))
  .sort()
  .map((filePath) => {
    const data = loadJson(filePath);
    const payload = getJuiPayload(data);
    return {
      filePath,
      rel: toRelPath(filePath),
      data,
      payload,
      nodeIssues: collectNodeIssues(payload?.root),
      flagIssues: flagTypeIssues(payload),
    };
  });

const customEntries = walkFiles(customDir, new Set([".json"]))
  .sort()
  .map((filePath) => {
    const data = loadJson(filePath);
    return {
      filePath,
      rel: toRelPath(filePath),
      data,
      keys: Object.keys(data || {}),
    };
  });

const integrationJuiEntries = walkFiles(integrationAppDir, new Set([".jui"]))
  .sort()
  .map((filePath) => {
    const payload = getJuiPayload(loadJson(filePath));
    return {
      filePath,
      rel: toRelPath(filePath),
      payload,
      nodeIssues: collectNodeIssues(payload?.root),
      flagIssues: flagTypeIssues(payload),
    };
  });

describe("fixture catalog regression :: smoke counts", () => {
  it("keeps demo fixture inventory non-empty", () => {
    expect(demoEntries.length).toBeGreaterThan(0);
  });

  it("keeps custom fixture inventory non-empty", () => {
    expect(customEntries.length).toBeGreaterThan(0);
  });

  it("keeps integration JUI fixture inventory non-empty", () => {
    expect(integrationJuiEntries.length).toBeGreaterThan(0);
  });
});

describe("fixture catalog regression :: demo templates", () => {
  for (const entry of demoEntries) {
    it(`[demo/parse] ${entry.rel}`, () => {
      expect(entry.data && typeof entry.data === "object").toBe(true);
    });

    it(`[demo/meta] ${entry.rel}`, () => {
      expect(typeof entry.data.id).toBe("string");
      expect(entry.data.id.length).toBeGreaterThan(0);
      expect(typeof entry.data.name).toBe("string");
      expect(entry.data.name.length).toBeGreaterThan(0);
      expect(typeof entry.data.description).toBe("string");
      expect(entry.data.description.length).toBeGreaterThan(0);
      expect(Array.isArray(entry.data.tags)).toBe(true);
      expect(entry.data.tags.length).toBeGreaterThan(0);
      expect(entry.data.tags.every((tag) => typeof tag === "string" && tag.trim().length > 0)).toBe(true);
    });

    it(`[demo/jui-core] ${entry.rel}`, () => {
      expect(entry.payload && typeof entry.payload === "object").toBe(true);
      expect(entry.payload.version).toBe(1);
      expect(entry.payload.root && typeof entry.payload.root === "object").toBe(true);
      expect(typeof entry.payload.root.type).toBe("string");
    });

    it(`[demo/window-contract] ${entry.rel}`, () => {
      expect(hasValidGeometry(entry.payload)).toBe(true);
      for (const key of FLAG_KEYS) {
        expect(typeof entry.payload[key]).toBe("boolean");
      }
    });

    it(`[demo/node-shape] ${entry.rel}`, () => {
      expect(entry.nodeIssues).toEqual([]);
      expect(entry.flagIssues).toEqual([]);
    });
  }
});

describe("fixture catalog regression :: custom component registry", () => {
  for (const entry of customEntries) {
    it(`[custom/parse] ${entry.rel}`, () => {
      expect(entry.data && typeof entry.data === "object").toBe(true);
    });

    it(`[custom/name] ${entry.rel}`, () => {
      expect(typeof entry.data.name).toBe("string");
      expect(entry.data.name.startsWith("Nui")).toBe(true);
    });

    it(`[custom/order] ${entry.rel}`, () => {
      expect(typeof entry.data.order).toBe("number");
      expect(Number.isFinite(entry.data.order)).toBe(true);
      expect(Number.isInteger(entry.data.order)).toBe(true);
      expect(entry.data.order).toBeGreaterThan(0);
    });

    it(`[custom/enabled] ${entry.rel}`, () => {
      expect(typeof entry.data.enabled).toBe("boolean");
    });

    it(`[custom/shape] ${entry.rel}`, () => {
      expect(entry.keys.sort()).toEqual(["enabled", "name", "order"]);
    });
  }
});

describe("fixture catalog regression :: integration JUI fixtures", () => {
  for (const entry of integrationJuiEntries) {
    it(`[jui/parse] ${entry.rel}`, () => {
      expect(entry.payload && typeof entry.payload === "object").toBe(true);
    });

    it(`[jui/core] ${entry.rel}`, () => {
      expect(entry.payload.version).toBe(1);
      expect(entry.payload.root && typeof entry.payload.root === "object").toBe(true);
      expect(typeof entry.payload.root.type).toBe("string");
    });

    it(`[jui/geometry] ${entry.rel}`, () => {
      if (Object.prototype.hasOwnProperty.call(entry.payload, "geometry")) {
        expect(hasValidGeometry(entry.payload)).toBe(true);
      } else {
        expect(entry.payload.geometry).toBeUndefined();
      }
    });

    it(`[jui/flags] ${entry.rel}`, () => {
      expect(entry.flagIssues).toEqual([]);
    });

    it(`[jui/node-shape] ${entry.rel}`, () => {
      expect(entry.nodeIssues).toEqual([]);
    });
  }
});
