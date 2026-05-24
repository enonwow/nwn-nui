import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";
import { describe, expect, it } from "vitest";
import { generateNuiResRefArtifacts } from "./nui";

const thisDir = dirname(fileURLToPath(import.meta.url));
const integrationTestsDir = resolve(thisDir, "../../../tests/app");

const contractProject = {
  name: "it_contract",
  windowId: "IT_WINDOW",
  eventScript: "it_window_ev",
};

function makeWindowProps(title, w, h) {
  return {
    jTitle: `JsonString("${title}")`,
    jGeometry: `NuiRect(-1.0, -1.0, ${w.toFixed(1)}, ${h.toFixed(1)})`,
    jResizable: "JsonBool(FALSE)",
    jCollapsed: "JsonBool(FALSE)",
    jClosable: "JsonBool(TRUE)",
    jTransparent: "JsonBool(FALSE)",
    jBorder: "JsonBool(TRUE)",
    jAcceptsInput: "JsonBool(TRUE)",
    jSizeConstraint: "JSON_NULL",
    jEdgeConstraint: "JSON_NULL",
    jFont: "JSON_STRING",
  };
}

function node(id, componentName, props = {}, children = []) {
  return { id, componentName, props, children };
}

function withHeight(id, height, child) {
  return node(id, "NuiHeight", { fHeight: height.toFixed(1) }, [child]);
}

function withWidth(id, width, child) {
  return node(id, "NuiWidth", { fWidth: width.toFixed(1) }, [child]);
}

function loadFixtureJui(fixtureName) {
  const fixturePath = resolve(integrationTestsDir, fixtureName, `${fixtureName}.jui`);
  const raw = readFileSync(fixturePath, "utf8");
  return JSON.parse(raw);
}

function canonicalize(value) {
  if (Array.isArray(value)) return value.map((entry) => canonicalize(entry));
  if (value && typeof value === "object") {
    const obj = /** @type {Record<string, unknown>} */ (value);
    /** @type {Record<string, unknown>} */
    const out = {};
    Object.keys(obj)
      .sort((a, b) => a.localeCompare(b))
      .forEach((key) => {
        out[key] = canonicalize(obj[key]);
      });
    return out;
  }
  return value;
}

function expectJuiWindowShape(payload, fixtureName) {
  expect(payload, `${fixtureName}: payload must be JSON object`).toBeTypeOf("object");
  expect(payload).not.toBeNull();
  const obj = /** @type {Record<string, unknown>} */ (payload);
  expect(obj.version, `${fixtureName}: missing/invalid version`).toBe(1);
  expect(obj.root, `${fixtureName}: missing root object`).toBeTypeOf("object");
  expect(obj.geometry, `${fixtureName}: missing geometry object`).toBeTypeOf("object");
}

function buildNuiButtonCase() {
  return [
    node("w1", "NuiWindow", makeWindowProps("NuiButton Test", 340, 120), [
      node("col1", "NuiCol", {}, [
        withHeight("h_spacer_top", 10, node("spacer_top", "NuiSpacer")),
        node("row1", "NuiRow", {}, [
          node("sp_left", "NuiSpacer"),
          withHeight("h_btn", 34, withWidth("w_btn", 180, node("btn1", "NuiButton", { jLabel: 'JsonString("Integration Button")' }))),
          node("sp_right", "NuiSpacer"),
        ]),
        withHeight("h_spacer_bottom", 10, node("spacer_bottom", "NuiSpacer")),
      ]),
    ]),
  ];
}

function buildNuiTextEditCase() {
  return [
    node("w1", "NuiWindow", makeWindowProps("NuiTextEdit Test", 360, 140), [
      node("col1", "NuiCol", {}, [
        withHeight("h_spacer_top", 10, node("spacer_top", "NuiSpacer")),
        node("row1", "NuiRow", {}, [
          node("sp_left", "NuiSpacer"),
          withHeight(
            "h_textedit",
            32,
            withWidth(
              "w_textedit",
              220,
              node("textedit1", "NuiTextEdit", {
                jPlaceholder: 'JsonString("Type here...")',
                jValue: 'NuiBind("it_nuitxt_bind")',
                nMaxLength: "64",
                bMultiline: "FALSE",
                bWordWrap: "TRUE",
              }),
            ),
          ),
          node("sp_right", "NuiSpacer"),
        ]),
        withHeight("h_spacer_bottom", 10, node("spacer_bottom", "NuiSpacer")),
      ]),
    ]),
  ];
}

function buildNuiSliderFloatCase() {
  return [
    node("w1", "NuiWindow", makeWindowProps("NuiSliderFloat Test", 420, 130), [
      node("col1", "NuiCol", {}, [
        withHeight("h_spacer_top", 14, node("spacer_top", "NuiSpacer")),
        node("row1", "NuiRow", {}, [
          node("sp_left", "NuiSpacer"),
          withWidth(
            "w_sliderf",
            280,
            node("sliderf1", "NuiSliderFloat", {
              jValue: 'NuiBind("it_nuislf_val")',
              jMin: 'NuiBind("it_nuislf_min")',
              jMax: 'NuiBind("it_nuislf_max")',
              jStepSize: 'NuiBind("it_nuislf_stp")',
            }),
          ),
          node("sp_right", "NuiSpacer"),
        ]),
        withHeight("h_spacer_bottom", 12, node("spacer_bottom", "NuiSpacer")),
      ]),
    ]),
  ];
}

describe("JUI integration contracts", () => {
  const cases = [
    { fixtureName: "nuibutton", buildRoot: buildNuiButtonCase },
    { fixtureName: "nuitextedit", buildRoot: buildNuiTextEditCase },
    { fixtureName: "nuisliderfloat", buildRoot: buildNuiSliderFloatCase },
  ];

  it.each(cases)("matches fixture: $fixtureName", ({ fixtureName, buildRoot }) => {
    const expectedFixture = loadFixtureJui(fixtureName);
    expectJuiWindowShape(expectedFixture, fixtureName);

    const generated = JSON.parse(generateNuiResRefArtifacts(contractProject, buildRoot()).juiContent);
    expectJuiWindowShape(generated, fixtureName);

    expect(canonicalize(generated)).toEqual(canonicalize(expectedFixture));
  });
});
