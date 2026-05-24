import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";
import { describe, expect, it } from "vitest";

const thisDir = dirname(fileURLToPath(import.meta.url));
const fixturesDir = resolve(thisDir, "../../../tests/app/nuiencsync");

const requiredFixtures = [
  "nuiencsync_shared_buttonselect.jui",
  "nuiencsync_shared_checks.jui",
  "nuiencsync_shared_id_dual_bind.jui",
  "nuiencsync_unique_buttonselect.jui",
  "nuiencsync_unique_id_shared_bind.jui",
  "nuiencsync_toggle_btn.jui",
  "encouraged-force-off-btn.jui",
  "nuiencsync_toggle_list.jui",
  "encouraged-force-off-list.jui",
  "nuiencsync_list_dual_track_toggle.jui",
  "nuiencsync_listcell_shards.jui",
];

function loadFixture(fileName) {
  const fixturePath = resolve(fixturesDir, fileName);
  return JSON.parse(readFileSync(fixturePath, "utf8"));
}

function collectEncouragedControls(node, inListRow = false, out = []) {
  if (Array.isArray(node)) {
    node.forEach((entry) => collectEncouragedControls(entry, inListRow, out));
    return out;
  }
  if (!node || typeof node !== "object") return out;

  if (Object.prototype.hasOwnProperty.call(node, "encouraged")) {
    const enc = node.encouraged;
    let bind = "";
    if (enc && typeof enc === "object" && typeof enc.bind === "string") bind = enc.bind;
    else if (typeof enc === "boolean") bind = enc ? "<literal:true>" : "<literal:false>";
    else if (enc != null) bind = String(enc);

    out.push({
      type: typeof node.type === "string" ? node.type : "",
      id: typeof node.id === "string" ? node.id : "",
      bind,
      inListRow,
    });
  }

  if (Array.isArray(node.children)) {
    collectEncouragedControls(node.children, inListRow, out);
  }

  if (Array.isArray(node.row_template)) {
    node.row_template.forEach((cell) => {
      if (Array.isArray(cell) && cell.length > 0) {
        collectEncouragedControls(cell[0], true, out);
      }
    });
  }

  return out;
}

function unique(values) {
  return [...new Set(values)];
}

describe("nuiencsync regression fixtures", () => {
  it("includes all required fixtures and at least one encouraged control in each", () => {
    requiredFixtures.forEach((fileName) => {
      const fixture = loadFixture(fileName);
      const controls = collectEncouragedControls(fixture.root);
      expect(controls.length, `${fileName} has no encouraged controls`).toBeGreaterThan(0);
    });
  });

  it("keeps shared-ID fixtures routed by one duplicated id", () => {
    ["nuiencsync_shared_buttonselect.jui", "nuiencsync_shared_checks.jui", "nuiencsync_shared_id_dual_bind.jui"].forEach((fileName) => {
      const controls = collectEncouragedControls(loadFixture(fileName).root);
      const ids = controls.map((control) => control.id).filter(Boolean);
      expect(ids.length, `${fileName} must have at least two encouraged IDs`).toBeGreaterThanOrEqual(2);
      expect(unique(ids), `${fileName} should keep one shared route key`).toHaveLength(1);
    });
  });

  it("keeps unique-ID fixtures isolated by id", () => {
    ["nuiencsync_unique_buttonselect.jui", "nuiencsync_unique_id_shared_bind.jui"].forEach((fileName) => {
      const controls = collectEncouragedControls(loadFixture(fileName).root);
      const ids = controls.map((control) => control.id).filter(Boolean);
      expect(ids.length, `${fileName} must have at least two encouraged IDs`).toBeGreaterThanOrEqual(2);
      expect(unique(ids).length, `${fileName} should not share route keys`).toBe(ids.length);
    });
  });

  it("keeps force-off single-button diagnostics with explicit OFF expectation text", () => {
    ["nuiencsync_toggle_btn.jui", "encouraged-force-off-btn.jui"].forEach((fileName) => {
      const fixture = loadFixture(fileName);
      const controls = collectEncouragedControls(fixture.root);
      expect(controls).toHaveLength(1);
      expect(JSON.stringify(fixture)).toContain("click #2 -> pulse OFF");
    });
  });

  it("keeps list-row force-off fixtures row-aware", () => {
    ["nuiencsync_toggle_list.jui", "encouraged-force-off-list.jui"].forEach((fileName) => {
      const fixture = loadFixture(fileName);
      const listNode = Array.isArray(fixture.root?.children)
        ? fixture.root.children.find((node) => node?.type === "list")
        : null;
      expect(listNode, `${fileName} requires list node`).toBeTruthy();
      expect(Number(listNode.row_count), `${fileName} row_count should cover multiple rows`).toBeGreaterThanOrEqual(2);
      const rowControls = collectEncouragedControls(fixture.root).filter((control) => control.inListRow);
      expect(rowControls.length, `${fileName} must keep encouraged control in row_template`).toBeGreaterThan(0);
    });
  });

  it("keeps dual-track list toggle isolated by id and bind", () => {
    const controls = collectEncouragedControls(loadFixture("nuiencsync_list_dual_track_toggle.jui").root).filter((control) => control.inListRow);
    const ids = unique(controls.map((control) => control.id).filter(Boolean));
    const binds = unique(controls.map((control) => control.bind).filter(Boolean));
    expect(ids.length).toBeGreaterThanOrEqual(2);
    expect(binds.length).toBeGreaterThanOrEqual(2);
  });

  it("keeps listcell shard split with two ids and two binds", () => {
    const controls = collectEncouragedControls(loadFixture("nuiencsync_listcell_shards.jui").root).filter((control) => control.inListRow);
    const ids = unique(controls.map((control) => control.id).filter(Boolean));
    const binds = unique(controls.map((control) => control.bind).filter(Boolean));
    expect(ids.length).toBeGreaterThanOrEqual(2);
    expect(binds.length).toBeGreaterThanOrEqual(2);
  });
});
