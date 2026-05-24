import { existsSync, readdirSync, readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";
import { describe, expect, it } from "vitest";

const thisDir = dirname(fileURLToPath(import.meta.url));
const fixturesDir = resolve(thisDir, "../../../tests/app/nuiduelui");
const assetsDir = resolve(fixturesDir, "assets");

const requiredFixtures = [
  "nuiduelui_duel_history.jui",
  "nuiduelui_duel_ranking.jui",
  "nuiduelui_duel_swaplayout.jui",
];

function loadFixture(fileName) {
  return JSON.parse(readFileSync(resolve(fixturesDir, fileName), "utf8"));
}

function walk(value, visit) {
  if (Array.isArray(value)) {
    value.forEach((entry) => walk(entry, visit));
    return;
  }
  if (!value || typeof value !== "object") return;
  visit(value);
  Object.values(value).forEach((entry) => walk(entry, visit));
}

function collectNodes(root, predicate) {
  const out = [];
  walk(root, (node) => {
    if (predicate(node)) out.push(node);
  });
  return out;
}

function unique(values) {
  return [...new Set(values)];
}

function collectImageRefs(root) {
  const refs = [];
  walk(root, (node) => {
    if (node.type === "button_image" && typeof node.label === "string") refs.push(node.label);
    if (Array.isArray(node.draw_list)) {
      node.draw_list.forEach((item) => {
        if (item && typeof item.image === "string") refs.push(item.image);
      });
    }
  });
  return unique(refs);
}

function assertListPreviewConsistency(listNode, fixtureName, idPrefix) {
  const rowTemplate = Array.isArray(listNode.row_template) ? listNode.row_template : [];
  expect(rowTemplate.length, `${fixtureName}:${idPrefix} row_template missing`).toBeGreaterThanOrEqual(3);

  const rowCountBind = listNode?.row_count?.bind;
  expect(typeof rowCountBind === "string" && rowCountBind.length > 0, `${fixtureName}:${idPrefix} row_count bind missing`).toBe(true);

  const preview = listNode.preview_binds ?? {};
  expect(preview && typeof preview === "object", `${fixtureName}:${idPrefix} preview_binds missing`).toBeTruthy();

  const previewRowCount = preview[rowCountBind];
  expect(typeof previewRowCount, `${fixtureName}:${idPrefix} preview row_count must be numeric`).toBe("number");
  expect(previewRowCount, `${fixtureName}:${idPrefix} preview row_count must be > 0`).toBeGreaterThan(0);

  const valueBindIds = unique(
    rowTemplate
      .map((cell) => (Array.isArray(cell) ? cell[0] : null))
      .map((entry) => entry?.value?.bind)
      .filter((bind) => typeof bind === "string"),
  );
  expect(valueBindIds.length, `${fixtureName}:${idPrefix} should expose multiple value binds`).toBeGreaterThanOrEqual(3);

  valueBindIds.forEach((bindId) => {
    const arr = preview[bindId];
    expect(Array.isArray(arr), `${fixtureName}:${idPrefix} missing preview array for ${bindId}`).toBe(true);
    expect(arr.length, `${fixtureName}:${idPrefix} preview length mismatch for ${bindId}`).toBe(previewRowCount);
  });

  const colorBindId =
    rowTemplate
      .map((cell) => (Array.isArray(cell) ? cell[0] : null))
      .map((entry) => entry?.foreground_color?.bind)
      .find((bind) => typeof bind === "string") ?? null;

  if (colorBindId) {
    const colorArr = preview[colorBindId];
    expect(Array.isArray(colorArr), `${fixtureName}:${idPrefix} missing preview color array`).toBe(true);
    expect(colorArr.length, `${fixtureName}:${idPrefix} preview color length mismatch`).toBe(previewRowCount);
  }
}

describe("nuiduelui regression fixtures", () => {
  it("keeps all required fixtures present and parseable", () => {
    requiredFixtures.forEach((fileName) => {
      const fixturePath = resolve(fixturesDir, fileName);
      expect(existsSync(fixturePath), `Missing fixture: ${fileName}`).toBe(true);
      const fixture = loadFixture(fileName);
      expect(fixture?.version, `${fileName} invalid version`).toBe(1);
      expect(fixture?.root && typeof fixture.root === "object", `${fileName} missing root`).toBeTruthy();
    });
  });

  it("keeps swaplayout fixture with 2 routes and 2 mapped list views", () => {
    const fixture = loadFixture("nuiduelui_duel_swaplayout.jui");
    const swapHosts = collectNodes(fixture.root, (node) => node?.swap_id === "it_duel_swap_main");
    expect(swapHosts).toHaveLength(1);

    const swapHost = swapHosts[0];
    expect(swapHost.swap_routes).toEqual(["it_duel_tab_log", "it_duel_tab_rank"]);
    expect(Array.isArray(swapHost.swap_views)).toBe(true);
    expect(swapHost.swap_views).toHaveLength(2);

    const [historyView, rankingView] = swapHost.swap_views;
    expect(historyView.type).toBe("list");
    expect(rankingView.type).toBe("list");
    expect(historyView?.row_count?.bind).toBe("duel_hist_row_count");
    expect(rankingView?.row_count?.bind).toBe("duel_rank_row_count");

    assertListPreviewConsistency(historyView, "nuiduelui_duel_swaplayout.jui", "swap_view_history");
    assertListPreviewConsistency(rankingView, "nuiduelui_duel_swaplayout.jui", "swap_view_ranking");
  });

  it("keeps standalone history/ranking list fixtures row-consistent", () => {
    const history = loadFixture("nuiduelui_duel_history.jui");
    const ranking = loadFixture("nuiduelui_duel_ranking.jui");

    const historyList = collectNodes(history.root, (node) => node?.type === "list" && node?.row_count?.bind === "duel_hist_row_count")[0];
    const rankingList = collectNodes(ranking.root, (node) => node?.type === "list" && node?.row_count?.bind === "duel_rank_row_count")[0];
    expect(historyList, "history list missing").toBeTruthy();
    expect(rankingList, "ranking list missing").toBeTruthy();

    assertListPreviewConsistency(historyList, "nuiduelui_duel_history.jui", "history_root_list");
    assertListPreviewConsistency(rankingList, "nuiduelui_duel_ranking.jui", "ranking_root_list");
  });

  it("keeps tab encouraged routing isolated to log/rank buttons", () => {
    const fixtureNames = [
      "nuiduelui_duel_history.jui",
      "nuiduelui_duel_ranking.jui",
      "nuiduelui_duel_swaplayout.jui",
    ];

    fixtureNames.forEach((fileName) => {
      const fixture = loadFixture(fileName);
      const encouragedNodes = collectNodes(
        fixture.root,
        (node) =>
          node?.type === "button_image" &&
          typeof node?.id === "string" &&
          (node.id === "it_duel_tab_log" || node.id === "it_duel_tab_rank"),
      );
      expect(encouragedNodes, `${fileName}: encouraged tab buttons missing`).toHaveLength(2);

      const routeMap = Object.fromEntries(encouragedNodes.map((node) => [node.id, node?.encouraged?.bind]));
      expect(routeMap.it_duel_tab_log, `${fileName}: log encouraged bind mismatch`).toBe("it_duel_enc_log");
      expect(routeMap.it_duel_tab_rank, `${fileName}: rank encouraged bind mismatch`).toBe("it_duel_enc_rank");

      const challenge = collectNodes(fixture.root, (node) => node?.type === "button_image" && node?.id === "it_duel_tab_challenge")[0];
      expect(challenge, `${fileName}: challenge button missing`).toBeTruthy();
      expect(challenge?.encouraged, `${fileName}: challenge should not have encouraged bind`).toBeUndefined();
    });
  });

  it("keeps image resrefs mapped to local fixture assets", () => {
    const assetResRefs = new Set(
      readdirSync(assetsDir)
        .filter((fileName) => fileName.toLowerCase().endsWith(".png"))
        .map((fileName) => fileName.replace(/\.png$/i, "")),
    );

    const usedRefs = new Set();
    requiredFixtures.forEach((fileName) => {
      const fixture = loadFixture(fileName);
      collectImageRefs(fixture.root).forEach((ref) => usedRefs.add(ref));
    });

    [...usedRefs].forEach((ref) => {
      expect(assetResRefs.has(ref), `Missing duel asset for ref "${ref}"`).toBe(true);
    });
  });
});
