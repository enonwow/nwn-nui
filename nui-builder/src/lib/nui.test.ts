import { describe, expect, it } from "vitest";
import { NUI_SIGNATURES } from "../data/nuiSignatures";
import { generateAssetManifest, generateDesignJson, generateNuiResRefPack, generateNuiScriptOutputArtifacts, generateNwLivePreviewPack, generateNwScript, parseComponentsFromText } from "./nui";
import type { NuiNode, NuiProjectMeta } from "../types";

function buildComponentMap() {
  const components = parseComponentsFromText(NUI_SIGNATURES);
  return new Map(components.map((component) => [component.name, component]));
}

describe("parseComponentsFromText", () => {
  it("parses known NUI signatures and categories", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    expect(parsed.length).toBeGreaterThan(20);

    const nuiImage = parsed.find((component) => component.name === "NuiImage");
    expect(nuiImage).toBeDefined();
    expect(nuiImage?.slotType).toBe("none");
    expect(nuiImage?.category).toBe("Components");
    expect(nuiImage?.defaults.jResRef).toBe('JsonString("")');
  });

  it("parses NuiCol as layout list container", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const nuiCol = parsed.find((component) => component.name === "NuiCol");
    expect(nuiCol).toBeDefined();
    expect(nuiCol?.slotType).toBe("list");
    expect(nuiCol?.category).toBe("Layout");
    expect(nuiCol?.args[0]?.name).toBe("jList");
  });

  it("parses NuiRow as layout list container", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const nuiRow = parsed.find((component) => component.name === "NuiRow");
    expect(nuiRow).toBeDefined();
    expect(nuiRow?.slotType).toBe("list");
    expect(nuiRow?.category).toBe("Layout");
    expect(nuiRow?.args[0]?.name).toBe("jList");
  });

  it("parses NuiSwapLayout as native layout container", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const swapLayout = parsed.find((component) => component.name === "NuiSwapLayout");
    expect(swapLayout).toBeDefined();
    expect(swapLayout?.slotType).toBe("list");
    expect(swapLayout?.category).toBe("Layout");
    expect(swapLayout?.args[0]?.name).toBe("jViews");
    expect(swapLayout?.defaults.sSwapId).toBe('"swap_main"');
    expect(swapLayout?.defaults.bBorder).toBe("FALSE");
    expect(swapLayout?.defaults.nScroll).toBe("NUI_SCROLLBARS_NONE");
  });

  it("parses NuiVisible with JsonBool(TRUE) default visibility", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const nuiVisible = parsed.find((component) => component.name === "NuiVisible");
    expect(nuiVisible).toBeDefined();
    expect(nuiVisible?.defaults.jVisible).toBe("JsonBool(TRUE)");
  });

  it("parses NuiButtonSelect with bool value default", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const nuiButtonSelect = parsed.find((component) => component.name === "NuiButtonSelect");
    expect(nuiButtonSelect).toBeDefined();
    expect(nuiButtonSelect?.defaults.jValue).toBe("JsonBool(FALSE)");
  });

  it("parses NuiCombo defaults with ComboEntry tuples and JsonInt selection", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const combo = parsed.find((component) => component.name === "NuiCombo");
    expect(combo).toBeDefined();
    expect(combo?.defaults.jSelected).toBe("JsonInt(0)");
    expect(combo?.defaults.jElements).toContain('NuiComboEntry("Label 1", 0)');
    expect(combo?.defaults.jElements).toContain('NuiComboEntry("Label 3", 2)');
  });

  it("parses NuiComboEntry helper defaults", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const comboEntry = parsed.find((component) => component.name === "NuiComboEntry");
    expect(comboEntry).toBeDefined();
    expect(comboEntry?.defaults.sLabel).toBe('"Label 1"');
    expect(comboEntry?.defaults.nValue).toBe("0");
  });

  it("parses NuiSlider defaults as discrete int contract", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const slider = parsed.find((component) => component.name === "NuiSlider");
    expect(slider).toBeDefined();
    expect(slider?.defaults.jValue).toBe("JsonInt(0)");
    expect(slider?.defaults.jMin).toBe("JsonInt(0)");
    expect(slider?.defaults.jMax).toBe("JsonInt(100)");
    expect(slider?.defaults.jStepSize).toBe("JsonInt(1)");
  });

  it("parses NuiSliderFloat defaults as float contract", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const sliderFloat = parsed.find((component) => component.name === "NuiSliderFloat");
    expect(sliderFloat).toBeDefined();
    expect(sliderFloat?.defaults.jValue).toBe("JsonFloat(0.5)");
    expect(sliderFloat?.defaults.jMin).toBe("JsonFloat(0.0)");
    expect(sliderFloat?.defaults.jMax).toBe("JsonFloat(1.0)");
    expect(sliderFloat?.defaults.jStepSize).toBe("JsonFloat(0.01)");
  });

  it("parses NuiProgress defaults as normalized float contract", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const progress = parsed.find((component) => component.name === "NuiProgress");
    expect(progress).toBeDefined();
    expect(progress?.defaults.jValue).toBe("JsonFloat(1.0)");
  });

  it("parses NuiTextEdit defaults with max length + multiline/wordwrap contract", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const textEdit = parsed.find((component) => component.name === "NuiTextEdit");
    expect(textEdit).toBeDefined();
    expect(textEdit?.defaults.jPlaceholder).toBe('JsonString("")');
    expect(textEdit?.defaults.jValue).toBe('JsonString("")');
    expect(textEdit?.defaults.nMaxLength).toBe("64");
    expect(textEdit?.defaults.bMultiline).toBe("FALSE");
    expect(textEdit?.defaults.bWordWrap).toBe("TRUE");
  });

  it("parses NuiList + NuiListTemplateCell defaults for decomp contract", () => {
    const parsed = parseComponentsFromText(NUI_SIGNATURES);
    const list = parsed.find((component) => component.name === "NuiList");
    const cell = parsed.find((component) => component.name === "NuiListTemplateCell");
    expect(list).toBeDefined();
    expect(cell).toBeDefined();
    expect(list?.slotType).toBe("list");
    expect(list?.args[0]?.name).toBe("jTemplate");
    expect(list?.defaults.jTemplate).toBeUndefined();
    expect(list?.defaults.jRowCount).toBe("JsonInt(0)");
    expect(list?.defaults.fRowHeight).toBe("NUI_STYLE_ROW_HEIGHT");
    expect(list?.defaults.bBorder).toBe("TRUE");
    expect(list?.defaults.nScroll).toBe("NUI_SCROLLBARS_Y");
    expect(cell?.defaults.fWidth).toBe("0.0");
    expect(cell?.defaults.bVariable).toBe("TRUE");
  });
});

describe("generateNwScript", () => {
  const project: NuiProjectMeta = {
    name: "test_project",
    windowId: "TEST_WINDOW",
    eventScript: "test_window_ev",
  };

  it("returns helpful message for empty root", () => {
    const map = buildComponentMap();
    const script = generateNwScript(project, [], map);
    expect(script).toContain("Empty project");
  });

  it("generates window creation script for simple tree", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("My Window")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiButton",
            props: {
              jLabel: 'JsonString("Click Me")',
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('#include "nw_inc_nui"');
    expect(script).toContain("void Build_test_project");
    expect(script).toContain("NuiButton(");
    expect(script).toContain('NuiCreate(oPC,');
    expect(script).toContain('TEST_WINDOW');
    expect(script).toContain("void test_window_ev()");
  });

  it("routes events for all generated window ids in multi-window layouts", () => {
    const map = buildComponentMap();
    const windowProps = {
      jTitle: 'JsonString("My Window")',
      jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
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
    const tree: NuiNode[] = [
      { id: "node_1", componentName: "NuiWindow", props: windowProps, children: [] },
      { id: "node_2", componentName: "NuiWindow", props: { ...windowProps, jTitle: 'JsonString("Window 2")' }, children: [] },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('"TEST_WINDOW"');
    expect(script).toContain('"TEST_WINDOW_2"');
    expect(script).toContain('if (sWindowId == "TEST_WINDOW" || sWindowId == "TEST_WINDOW_2")');
  });

  it("keeps NuiStrRef object payload as text source in generated script", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("My Window")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiLabel",
            props: {
              jValue: '{"strref": 161}',
              jHAlign: "JsonInt(NUI_HALIGN_LEFT)",
              jVAlign: "JsonInt(NUI_VALIGN_MIDDLE)",
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("NuiStrRef(161)");
    expect(script).not.toContain('JsonString("{\\"strref\\": 161}")');
  });

  it("preserves NuiLabel alignment expressions, including JSON_NULL", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Label Align")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiLabel",
            props: {
              jValue: 'JsonString("Row label")',
              jHAlign: "JsonInt(NUI_HALIGN_RIGHT)",
              jVAlign: "JSON_NULL",
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiLabel(JsonString("Row label"), JsonInt(NUI_HALIGN_RIGHT), JSON_NULL)');
  });

  it("emits NuiText with default border and auto scroll", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Text Defaults")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiText",
            props: {
              jValue: 'JsonString("Readonly text")',
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiText(JsonString("Readonly text"), TRUE, NUI_SCROLLBARS_AUTO)');
  });

  it("preserves NuiText explicit border and scrollbar settings", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Text Overrides")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiText",
            props: {
              jValue: 'JsonString("No frame")',
              bBorder: "FALSE",
              nScroll: "NUI_SCROLLBARS_NONE",
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiText(JsonString("No frame"), FALSE, NUI_SCROLLBARS_NONE)');
  });

  it("emits NuiTextEdit with placeholder/value/max/multiline/wordwrap args", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("TextEdit")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiTextEdit",
            props: {
              jPlaceholder: 'JsonString("Type here")',
              jValue: 'JsonString("abc")',
              nMaxLength: "128",
              bMultiline: "TRUE",
              bWordWrap: "FALSE",
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiTextEdit(JsonString("Type here"), JsonString("abc"), 128, TRUE, FALSE)');
  });

  it("emits NuiList with row template cell tuples and row_count/row_height/border/scrollbars", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("List")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiList",
            props: {
              jRowCount: 'NuiBind("row_count")',
              fRowHeight: "NUI_STYLE_ROW_HEIGHT",
              bBorder: "TRUE",
              nScroll: "NUI_SCROLLBARS_AUTO",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiListTemplateCell",
                props: {
                  fWidth: "120.0",
                  bVariable: "FALSE",
                },
                children: [
                  {
                    id: "node_4",
                    componentName: "NuiButton",
                    props: { jLabel: 'JsonString("Row Action")' },
                    children: [],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiListTemplateCell(j_NuiButton_');
    expect(script).toContain(', 120.0, FALSE)');
    expect(script).toContain('NuiList(jList_');
    expect(script).toContain('NuiBind("row_count"), NUI_STYLE_ROW_HEIGHT, TRUE, NUI_SCROLLBARS_AUTO)');
  });

  it("adds commented open-event NuiSetBind init stubs for detected binds", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("List")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiList",
            props: {
              jRowCount: 'NuiBind("row_count")',
              fRowHeight: "NUI_STYLE_ROW_HEIGHT",
              bBorder: "TRUE",
              nScroll: "NUI_SCROLLBARS_Y",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiListTemplateCell",
                props: {
                  fWidth: "120.0",
                  bVariable: "TRUE",
                },
                children: [
                  {
                    id: "node_4",
                    componentName: "NuiLabel",
                    props: {
                      jValue: 'NuiBind("row_name")',
                      jHAlign: "JsonInt(NUI_HALIGN_LEFT)",
                      jVAlign: "JsonInt(NUI_VALIGN_MIDDLE)",
                    },
                    children: [],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('if (sEventType == "open")');
    expect(script).toContain('Uncomment + adjust values to initialize your NuiBind(...) data on window open.');
    expect(script).toContain('// NuiSetBind(oPC, nToken, "row_count", JsonInt(0));');
    expect(script).toContain('// NuiSetBind(oPC, nToken, "row_name", JsonArray());');
  });

  it("overrides open-event bind stubs with preview row data and bind-row count", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Preview List")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiList",
            props: {
              jRowCount: 'NuiBind("rows_count")',
              __previewRowsJson: '[{"row_name":"Alpha","row_value":10},{"row_name":"Beta","row_value":11}]',
              fRowHeight: "NUI_STYLE_ROW_HEIGHT",
              bBorder: "TRUE",
              nScroll: "NUI_SCROLLBARS_Y",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiListTemplateCell",
                props: {
                  fWidth: "120.0",
                  bVariable: "TRUE",
                },
                children: [
                  {
                    id: "node_4",
                    componentName: "NuiLabel",
                    props: {
                      jValue: 'NuiBind("row_name")',
                      jHAlign: "JsonInt(NUI_HALIGN_LEFT)",
                      jVAlign: "JsonInt(NUI_VALIGN_MIDDLE)",
                    },
                    children: [],
                  },
                  {
                    id: "node_5",
                    componentName: "NuiSlider",
                    props: {
                      jValue: 'NuiBind("row_value")',
                      jMin: "JsonInt(0)",
                      jMax: "JsonInt(100)",
                      jStepSize: "JsonInt(1)",
                    },
                    children: [],
                  },
                  {
                    id: "node_6",
                    componentName: "NuiButton",
                    props: {
                      jLabel: 'NuiBind("action_label")',
                    },
                    children: [],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('if (sEventType == "open")');
    expect(script).toContain('// NuiSetBind(oPC, nToken, "rows_count", JsonInt(2));');
    expect(script).toContain('// NuiSetBind(oPC, nToken, "row_name", JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonString("Alpha")), JsonString("Beta")));');
    expect(script).toContain('// NuiSetBind(oPC, nToken, "row_value", JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonInt(10)), JsonInt(11)));');
    expect(script).toContain('// NuiSetBind(oPC, nToken, "action_label", JsonArray());');
  });

  it("infers practical default init values for non-template NuiBind usage", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Bind Defaults")',
          jGeometry: "NuiRect(-1.0, -1.0, 560.0, 220.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiRow",
            props: {},
            children: [
              {
                id: "node_3",
                componentName: "NuiSliderFloat",
                props: {
                  jValue: 'NuiBind("volume_value", 0, 2, 0)',
                  jMin: "JsonFloat(0.0)",
                  jMax: "JsonFloat(1.0)",
                  jStepSize: "JsonFloat(0.05)",
                },
                children: [],
              },
              {
                id: "node_4",
                componentName: "NuiLabel",
                props: {
                  jValue: 'NuiBind("volume_label")',
                  jHAlign: "JsonInt(NUI_HALIGN_RIGHT)",
                  jVAlign: "JsonInt(NUI_VALIGN_MIDDLE)",
                },
                children: [],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('// NuiSetBind(oPC, nToken, "volume_label", JsonString(""));');
    expect(script).toContain('// NuiSetBind(oPC, nToken, "volume_value", JsonFloat(0.0));');
  });

  it("emits NuiButton with label payload (click button contract)", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Button")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiButton",
            props: {
              jLabel: 'JsonString("OK")',
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiButton(JsonString("OK"))');
  });

  it("routes click handler template by NuiId around NuiButton", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Button Route")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiId",
            props: {
              sId: 'JsonString("btn_ok")',
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiButton",
                props: {
                  jLabel: 'JsonString("OK")',
                },
                children: [],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('// Routed by NuiId / NuiGetEventElement()');
    expect(script).toContain('if (sEventElem == "btn_ok")');
    expect(script).toContain("// TODO: handle btn_ok");
  });

  it("keeps button variants distinct (button vs button_select vs button_image)", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Buttons")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          { id: "node_2", componentName: "NuiButton", props: { jLabel: 'JsonString("Apply")' }, children: [] },
          { id: "node_3", componentName: "NuiButtonSelect", props: { jLabel: 'JsonString("Select")', jValue: "JsonBool(FALSE)" }, children: [] },
          { id: "node_4", componentName: "NuiButtonImage", props: { jResRef: 'JsonString("icon_ok")' }, children: [] },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("NuiButton(");
    expect(script).toContain("NuiButtonSelect(");
    expect(script).toContain("NuiButtonImage(");
    expect((script.match(/NuiButton\(/g) ?? []).length).toBeGreaterThanOrEqual(1);
    expect((script.match(/NuiButtonSelect\(/g) ?? []).length).toBeGreaterThanOrEqual(1);
    expect((script.match(/NuiButtonImage\(/g) ?? []).length).toBeGreaterThanOrEqual(1);
  });

  it("emits NuiButtonSelect with explicit bool bind channel", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Select Bind")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiButtonSelect",
            props: {
              jLabel: 'JsonString("On/Off")',
              jValue: 'NuiBind("flag")',
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiButtonSelect(JsonString("On/Off"), NuiBind("flag"))');
  });

  it("routes click handler template by NuiId around NuiButtonSelect", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Select Route")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiId",
            props: {
              sId: 'JsonString("btn_toggle")',
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiButtonSelect",
                props: {
                  jLabel: 'JsonString("Toggle")',
                  jValue: "JsonBool(FALSE)",
                },
                children: [],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('// Routed by NuiId / NuiGetEventElement()');
    expect(script).toContain('if (sEventElem == "btn_toggle")');
    expect(script).toContain("// TODO: handle btn_toggle");
  });

  it("serializes NuiDrawList as host element plus draw list payload", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("DrawList Host")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiDrawList",
            props: {
              jScissor: "JsonInt(0)",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiButton",
                props: { jLabel: 'JsonString("Host")' },
                children: [],
              },
              {
                id: "node_4",
                componentName: "NuiDrawListText",
                props: {
                  jEnabled: "JsonBool(TRUE)",
                  jColor: "NuiColor(255, 255, 255, 255)",
                  jRect: "NuiRect(0.0, 0.0, 120.0, 24.0)",
                  jText: 'JsonString("Hover text")',
                  nOrder: "NUI_DRAW_LIST_ITEM_ORDER_AFTER",
                  nRender: "NUI_DRAW_LIST_ITEM_RENDER_MOUSE_HOVER",
                  nBindArrays: "FALSE",
                  jFont: "JSON_STRING",
                },
                children: [],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toMatch(/NuiDrawList\(j_NuiButton_\d+,\s*JsonInt\(0\),\s*jList_\d+\)/);
    expect(script).toContain("NuiDrawListText(");
    // Regression guard: support nBindArrays trailing arg for nw_inc_nui variants
    // that include it in NuiDrawList* signatures.
    const drawTextCall = script.match(/NuiDrawListText\(([^;]+)\);/);
    expect(drawTextCall).not.toBeNull();
    expect(drawTextCall?.[1] ?? "").toMatch(/,\s*FALSE\s*$/);
    expect(script).toContain('if (sEventType == "mousedown" || sEventType == "mouseup" || sEventType == "mousescroll")');
    expect(script).toContain("int nArrayIndex   = NuiGetEventArrayIndex();");
    expect(script).toContain("json jPayload     = NuiGetEventPayload();");
  });

  it("normalizes draw-list rect fill to bool and line thickness to explicit float", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("DrawList Rect")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiDrawList",
            props: {
              jScissor: "JsonBool(TRUE)",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiGroup",
                props: {
                  bBorder: "TRUE",
                  nScroll: "NUI_SCROLLBARS_NONE",
                },
                children: [],
              },
              {
                id: "node_4",
                componentName: "NuiDrawListRect",
                props: {
                  jEnabled: "JsonBool(TRUE)",
                  jColor: "NuiColor(255, 170, 96, 255)",
                  jFill: "NuiColor(21, 42, 78, 200)",
                  jLineThickness: "JsonInt(2)",
                  jRect: "NuiRect(30, 42, 300, 140)",
                  nOrder: "NUI_DRAW_LIST_ITEM_ORDER_AFTER",
                  nRender: "NUI_DRAW_LIST_ITEM_RENDER_ALWAYS",
                },
                children: [],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("NuiDrawListRect(");
    expect(script).toContain("JsonBool(TRUE), JsonFloat(2.0), NuiRect(30.0, 42.0, 300.0, 140.0)");
    expect(script).toContain(", NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, FALSE);");
  });

  it("normalizes draw-list polyline points from {x,y} objects into float pairs", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("DrawList PolyLine")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiDrawList",
            props: {
              jScissor: "JsonBool(TRUE)",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiGroup",
                props: {
                  bBorder: "TRUE",
                  nScroll: "NUI_SCROLLBARS_NONE",
                },
                children: [],
              },
              {
                id: "node_4",
                componentName: "NuiDrawListPolyLine",
                props: {
                  jEnabled: "JsonBool(TRUE)",
                  jColor: "NuiColor(255, 179, 92, 255)",
                  jFill: "JsonBool(FALSE)",
                  jLineThickness: "JsonFloat(3.0)",
                  jPoints:
                    'JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonObjectSet(JsonObjectSet(JsonObject(), JsonString("x"), JsonFloat(30.0)), JsonString("y"), JsonFloat(210.0))), JsonObjectSet(JsonObjectSet(JsonObject(), JsonString("x"), JsonFloat(92.0)), JsonString("y"), JsonFloat(120.0)))',
                  nOrder: "NUI_DRAW_LIST_ITEM_ORDER_AFTER",
                  nRender: "NUI_DRAW_LIST_ITEM_RENDER_ALWAYS",
                },
                children: [],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("NuiDrawListPolyLine(");
    expect(script).toContain("JsonFloat(30.0)");
    expect(script).toContain("JsonFloat(210.0)");
    expect(script).toContain("JsonFloat(92.0)");
    expect(script).toContain("JsonFloat(120.0)");
    expect(script).toContain(", NUI_DRAW_LIST_ITEM_RENDER_ALWAYS, FALSE);");
  });

  it("preserves NuiCol child order with mixed layout and element nodes", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("My Window")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiCol",
            props: {},
            children: [
              {
                id: "node_3",
                componentName: "NuiButton",
                props: { jLabel: 'JsonString("First")' },
                children: [],
              },
              {
                id: "node_4",
                componentName: "NuiSpacer",
                props: {},
                children: [],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("NuiCol(");
    const buttonIdx = script.indexOf("NuiButton(");
    const spacerIdx = script.indexOf("NuiSpacer(");
    expect(buttonIdx).toBeGreaterThan(-1);
    expect(spacerIdx).toBeGreaterThan(-1);
    expect(buttonIdx).toBeLessThan(spacerIdx);
  });

  it("emits NuiSpacer as zero-argument widget", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Spacer")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiRow",
            props: {},
            children: [
              { id: "node_3", componentName: "NuiSpacer", props: {}, children: [] },
              { id: "node_4", componentName: "NuiButton", props: { jLabel: 'JsonString("Center")' }, children: [] },
              { id: "node_5", componentName: "NuiSpacer", props: {}, children: [] },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("NuiSpacer()");
    expect(script).not.toMatch(/NuiSpacer\([^)]/);
  });

  it("serializes nested NuiCol/NuiRow without flattening", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Nested")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiCol",
            props: {},
            children: [
              {
                id: "node_3",
                componentName: "NuiRow",
                props: {},
                children: [
                  {
                    id: "node_4",
                    componentName: "NuiCol",
                    props: {},
                    children: [
                      {
                        id: "node_5",
                        componentName: "NuiButton",
                        props: { jLabel: 'JsonString("Deep Child")' },
                        children: [],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    const colCount = (script.match(/NuiCol\(/g) ?? []).length;
    const rowCount = (script.match(/NuiRow\(/g) ?? []).length;
    expect(colCount).toBeGreaterThanOrEqual(2);
    expect(rowCount).toBeGreaterThanOrEqual(1);
    expect(script).toContain('JsonString("Deep Child")');
  });

  it("preserves NuiRow child order with mixed layout and element nodes", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Row Order")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiRow",
            props: {},
            children: [
              {
                id: "node_3",
                componentName: "NuiButton",
                props: { jLabel: 'JsonString("Left")' },
                children: [],
              },
              {
                id: "node_4",
                componentName: "NuiCol",
                props: {},
                children: [
                  {
                    id: "node_5",
                    componentName: "NuiLabel",
                    props: {
                      jValue: 'JsonString("Right-Col")',
                      jHAlign: "JsonInt(NUI_HALIGN_LEFT)",
                      jVAlign: "JsonInt(NUI_VALIGN_MIDDLE)",
                    },
                    children: [],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("NuiRow(");
    expect(script).toContain('JsonString("Left")');
    expect(script).toContain('JsonString("Right-Col")');
  });

  it("keeps NuiRow children intact when wrapped by modifiers", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Wrapped Row")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiHeight",
            props: { fHeight: "64.0" },
            children: [
              {
                id: "node_3",
                componentName: "NuiGroup",
                props: { bBorder: "TRUE", nScroll: "NUI_SCROLLBARS_AUTO" },
                children: [
                  {
                    id: "node_4",
                    componentName: "NuiMargin",
                    props: { fMargin: "8.0" },
                    children: [
                      {
                        id: "node_5",
                        componentName: "NuiRow",
                        props: {},
                        children: [
                          {
                            id: "node_6",
                            componentName: "NuiButton",
                            props: { jLabel: 'JsonString("A")' },
                            children: [],
                          },
                          {
                            id: "node_7",
                            componentName: "NuiButton",
                            props: { jLabel: 'JsonString("B")' },
                            children: [],
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("NuiHeight(");
    expect(script).toContain("NuiGroup(");
    expect(script).toContain("NuiMargin(");
    expect(script).toContain("NuiRow(");
    const aIdx = script.indexOf('JsonString("A")');
    const bIdx = script.indexOf('JsonString("B")');
    expect(aIdx).toBeGreaterThan(-1);
    expect(bIdx).toBeGreaterThan(-1);
    expect(aIdx).toBeLessThan(bIdx);
  });

  it("serializes NuiGroup as single-child wrapper for one child", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Group Single")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiGroup",
            props: {
              bBorder: "TRUE",
              nScroll: "NUI_SCROLLBARS_AUTO",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiButton",
                props: { jLabel: 'JsonString("Only Child")' },
                children: [],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("NuiGroup(");
    expect(script).toMatch(/NuiGroup\(j_NuiButton_\d+,\s*TRUE,\s*NUI_SCROLLBARS_AUTO\)/);
    expect(script).not.toMatch(/NuiGroup\(jList_\d+/);
  });

  it("auto-wraps multi-child NuiGroup into NuiCol while preserving order", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Group Multi")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiGroup",
            props: {
              bBorder: "TRUE",
              nScroll: "NUI_SCROLLBARS_AUTO",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiButton",
                props: { jLabel: 'JsonString("First")' },
                children: [],
              },
              {
                id: "node_4",
                componentName: "NuiButton",
                props: { jLabel: 'JsonString("Second")' },
                children: [],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toMatch(/NuiGroup\(j_NuiCol_\d+,\s*TRUE,\s*NUI_SCROLLBARS_AUTO\)/);
    const firstIdx = script.indexOf('JsonString("First")');
    const secondIdx = script.indexOf('JsonString("Second")');
    expect(firstIdx).toBeGreaterThan(-1);
    expect(secondIdx).toBeGreaterThan(-1);
    expect(firstIdx).toBeLessThan(secondIdx);
  });

  it("emits NuiCombo with explicit ComboEntry tuple values and index selection", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Combo")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiCombo",
            props: {
              jElements:
                'JsonArrayInsert(JsonArrayInsert(JsonArrayInsert(JsonArray(), NuiComboEntry("Label 1", 7)), NuiComboEntry("Label 2", 11)), NuiComboEntry("Label 3", 42))',
              jSelected: "JsonInt(2)",
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("NuiCombo(");
    expect(script).toContain('NuiComboEntry("Label 1", 7)');
    expect(script).toContain('NuiComboEntry("Label 3", 42)');
    expect(script).toContain("JsonInt(2)");
  });

  it("emits NuiSlider with int value/min/max/step payload", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Slider")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiSlider",
            props: {
              jValue: 'NuiBind("volume")',
              jMin: "JsonInt(0)",
              jMax: "JsonInt(100)",
              jStepSize: "JsonInt(1)",
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiSlider(NuiBind("volume"), JsonInt(0), JsonInt(100), JsonInt(1))');
  });

  it("emits NuiSliderFloat with float value/min/max/step payload", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("SliderFloat")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiSliderFloat",
            props: {
              jValue: 'NuiBind("vf")',
              jMin: "JsonFloat(0.0)",
              jMax: "JsonFloat(1.0)",
              jStepSize: "JsonFloat(0.01)",
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiSliderFloat(NuiBind("vf"), JsonFloat(0.0), JsonFloat(1.0), JsonFloat(0.01))');
  });

  it("emits NuiProgress with progress type value channel payload", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Progress")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiProgress",
            props: {
              jValue: 'NuiBind("p")',
            },
            children: [],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiProgress(NuiBind("p"))');
  });

  it("auto-generates encouraged bool click toggle using lib helpers", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Enc Bool Toggle")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiId",
            props: { sId: 'JsonString("encToggleBtn")' },
            children: [
              {
                id: "node_3",
                componentName: "NuiEncouraged",
                props: { jEncouraged: 'NuiBind("enc_toggle_btn")' },
                children: [
                  {
                    id: "node_4",
                    componentName: "NuiButton",
                    props: { jLabel: 'JsonString("Toggle")' },
                    children: [],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('#include "lib_nui"');
    expect(script).toContain('if (sEventElem == "encToggleBtn")');
    expect(script).toContain('json jEncCurrent1 = NuiLib_GetBindOrDefault(oPC, nToken, "enc_toggle_btn", JsonBool(FALSE));');
    expect(script).toContain('NuiLib_SetBindSafe(oPC, nToken, "enc_toggle_btn", JsonBool(!bEncCurrent1));');
    expect(script).toContain('if (JsonGetType(NuiGetBind(oPC, nToken, "enc_toggle_btn")) == JSON_TYPE_NULL)');
    expect(script).toContain('NuiSetBind(oPC, nToken, "enc_toggle_btn", JsonBool(FALSE));');
  });

  it("auto-generates encouraged list-row toggle with row-aware helper and init", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Enc List Toggle")',
          jGeometry: "NuiRect(-1.0, -1.0, 720.0, 360.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiList",
            props: {
              jRowCount: "JsonInt(5)",
              fRowHeight: "34.0",
              bBorder: "TRUE",
              nScroll: "NUI_SCROLLBARS_Y",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiListTemplateCell",
                props: { fWidth: "220.0", bVariable: "FALSE" },
                children: [
                  {
                    id: "node_4",
                    componentName: "NuiId",
                    props: { sId: 'JsonString("encListRowBtn")' },
                    children: [
                      {
                        id: "node_5",
                        componentName: "NuiEncouraged",
                        props: { jEncouraged: 'NuiBind("enc_list_rows")' },
                        children: [
                          {
                            id: "node_6",
                            componentName: "NuiButton",
                            props: { jLabel: 'JsonString("Select")' },
                            children: [],
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('#include "lib_nui"');
    expect(script).toContain('if (sEventElem == "encListRowBtn")');
    expect(script).toContain('NuiLib_EncouragedToggleRow(oPC, nToken, nArrayIndex, nEncRowCount1, "enc_list_rows", "__enc_row_enc_list_rows");');
    expect(script).toContain('int nEncRowCount1 = 5;');
    expect(script).toContain('json jEncInit1 = NuiGetBind(oPC, nToken, "enc_list_rows");');
    expect(script).toContain('NuiSetBind(oPC, nToken, "enc_list_rows", jEncInit1);');
    expect(script).toContain('NuiSetBind(oPC, nToken, "__enc_row_enc_list_rows", JsonNull());');
  });

  it("resolves encouraged list-row count from NuiBind when jRowCount is dynamic", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Enc List Toggle Dynamic Rows")',
          jGeometry: "NuiRect(-1.0, -1.0, 720.0, 360.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiList",
            props: {
              jRowCount: 'NuiBind("rows_count")',
              fRowHeight: "34.0",
              bBorder: "TRUE",
              nScroll: "NUI_SCROLLBARS_Y",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiListTemplateCell",
                props: { fWidth: "220.0", bVariable: "FALSE" },
                children: [
                  {
                    id: "node_4",
                    componentName: "NuiId",
                    props: { sId: 'JsonString("encListRowBtnDynamic")' },
                    children: [
                      {
                        id: "node_5",
                        componentName: "NuiEncouraged",
                        props: { jEncouraged: 'NuiBind("enc_list_rows_dynamic")' },
                        children: [
                          {
                            id: "node_6",
                            componentName: "NuiButton",
                            props: { jLabel: 'JsonString("Select")' },
                            children: [],
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('json jEncRowCount1 = NuiLib_GetBindOrDefault(oPC, nToken, "rows_count", JsonInt(0));');
    expect(script).toContain("int nEncRowCount1 = JsonGetInt(jEncRowCount1);");
    expect(script).toContain('NuiLib_EncouragedToggleRow(oPC, nToken, nArrayIndex, nEncRowCount1, "enc_list_rows_dynamic", "__enc_row_enc_list_rows_dynamic");');
  });

  it("sanitizes encouraged row helper bind key for special characters", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Enc List Toggle Key Sanitization")',
          jGeometry: "NuiRect(-1.0, -1.0, 720.0, 360.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiList",
            props: {
              jRowCount: "JsonInt(3)",
              fRowHeight: "34.0",
              bBorder: "TRUE",
              nScroll: "NUI_SCROLLBARS_Y",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiListTemplateCell",
                props: { fWidth: "220.0", bVariable: "FALSE" },
                children: [
                  {
                    id: "node_4",
                    componentName: "NuiId",
                    props: { sId: 'JsonString("encListRowBtnSpecialBind")' },
                    children: [
                      {
                        id: "node_5",
                        componentName: "NuiEncouraged",
                        props: { jEncouraged: 'NuiBind("  .enc-list rows.01  ")' },
                        children: [
                          {
                            id: "node_6",
                            componentName: "NuiButton",
                            props: { jLabel: 'JsonString("Select")' },
                            children: [],
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain('NuiLib_EncouragedToggleRow(oPC, nToken, nArrayIndex, nEncRowCount1, ".enc-list rows.01", "__enc_row_enc_list_rows_01");');
    expect(script).toContain('if (JsonGetType(NuiGetBind(oPC, nToken, "__enc_row_enc_list_rows_01")) == JSON_TYPE_NULL)');
    expect(script).toContain('NuiSetBind(oPC, nToken, "__enc_row_enc_list_rows_01", JsonNull());');
  });

  it("initializes shared encouraged list bind for each list context", () => {
    const map = buildComponentMap();
    const listProps = {
      fRowHeight: "34.0",
      bBorder: "TRUE",
      nScroll: "NUI_SCROLLBARS_Y",
    };
    const buildList = (nodePrefix: string, nuiId: string, rowCount: string): NuiNode => ({
      id: `${nodePrefix}_list`,
      componentName: "NuiList",
      props: { ...listProps, jRowCount: rowCount },
      children: [
        {
          id: `${nodePrefix}_cell`,
          componentName: "NuiListTemplateCell",
          props: { fWidth: "220.0", bVariable: "FALSE" },
          children: [
            {
              id: `${nodePrefix}_id`,
              componentName: "NuiId",
              props: { sId: `JsonString("${nuiId}")` },
              children: [
                {
                  id: `${nodePrefix}_enc`,
                  componentName: "NuiEncouraged",
                  props: { jEncouraged: 'NuiBind("enc_shared_rows")' },
                  children: [
                    {
                      id: `${nodePrefix}_btn`,
                      componentName: "NuiButton",
                      props: { jLabel: 'JsonString("Toggle")' },
                      children: [],
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    });

    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Enc Shared Rows")',
          jGeometry: "NuiRect(-1.0, -1.0, 720.0, 360.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [buildList("node_2", "encListRowSmall", "JsonInt(1)"), buildList("node_3", "encListRowBig", "JsonInt(6)")],
      },
    ];

    const script = generateNwScript(project, tree, map);
    expect(script).toContain("int nEncRowCount1 = 1;");
    expect(script).toContain("int nEncRowCount2 = 6;");
  });
});

describe("generateNuiScriptOutputArtifacts", () => {
  it("keeps layout section helper functions in project script output", () => {
    const map = buildComponentMap();
    const project: NuiProjectMeta = {
      name: "nui_project",
      windowId: "NUI_WINDOW",
      eventScript: "nui_window_ev",
    };
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Window")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiCol",
            props: {},
            children: [{ id: "node_3", componentName: "NuiButton", props: { jLabel: 'JsonString("A")' }, children: [] }],
          },
          {
            id: "node_4",
            componentName: "NuiRow",
            props: {},
            children: [{ id: "node_5", componentName: "NuiButton", props: { jLabel: 'JsonString("B")' }, children: [] }],
          },
        ],
      },
    ];

    const artifacts = generateNuiScriptOutputArtifacts(project, tree, map);
    expect(artifacts.projectScript).toContain("Auto-generated layout section functions (readability helpers)");
    expect(artifacts.projectScript).toContain("BuildSection_");
    expect(artifacts.eventScript).not.toContain("Auto-generated layout section functions (readability helpers)");
    expect(artifacts.includeCustomLib).toBe(false);
  });

  it("supports merged script output mode", () => {
    const map = buildComponentMap();
    const project: NuiProjectMeta = {
      name: "nui_project",
      windowId: "NUI_WINDOW",
      eventScript: "nui_window_ev",
      mergeScripts: true,
    };
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Window")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [{ id: "node_2", componentName: "NuiCol", props: {}, children: [] }],
      },
    ];

    const artifacts = generateNuiScriptOutputArtifacts(project, tree, map, { mergeScripts: true });
    expect(artifacts.mergeScripts).toBe(true);
    expect(artifacts.projectScript).toContain("void Build_nui_project(object oPC)");
    expect(artifacts.projectScript).toContain("void nui_window_ev()");
    expect(artifacts.eventScript).toBe("");
    expect(artifacts.includeCustomLib).toBe(false);
  });

  it("includes encouraged helper library and OFF branch for row toggle", () => {
    const map = buildComponentMap();
    const project: NuiProjectMeta = {
      name: "nui_project",
      windowId: "NUI_WINDOW",
      eventScript: "nui_window_ev",
    };
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Enc Lib")',
          jGeometry: "NuiRect(-1.0, -1.0, 720.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiId",
            props: { sId: 'JsonString("encLibBtn")' },
            children: [
              {
                id: "node_3",
                componentName: "NuiEncouraged",
                props: { jEncouraged: 'NuiBind("enc_lib")' },
                children: [
                  { id: "node_4", componentName: "NuiButton", props: { jLabel: 'JsonString("A")' }, children: [] },
                ],
              },
            ],
          },
        ],
      },
    ];

    const artifacts = generateNuiScriptOutputArtifacts(project, tree, map);
    expect(artifacts.includeCustomLib).toBe(true);
    expect(artifacts.eventScript).toContain('#include "lib_nui"');
    expect(artifacts.customLibScript).toContain("void NuiLib_EncouragedToggleRow(");
    expect(artifacts.customLibScript).toContain("if (bWasEnabled)");
    expect(artifacts.customLibScript).toContain("JsonBool(FALSE)");
    expect(artifacts.customLibScript).toContain("JsonNull()");
  });
});

describe("generateDesignJson", () => {
  it("preserves row nodes and children payload in save output", () => {
    const project: NuiProjectMeta = {
      name: "row_save",
      windowId: "ROW_WINDOW",
      eventScript: "row_event",
    };
    const root: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiRow",
        props: {},
        children: [
          {
            id: "node_2",
            componentName: "NuiButton",
            props: { jLabel: 'JsonString("L")' },
            children: [],
          },
          {
            id: "node_3",
            componentName: "NuiButton",
            props: { jLabel: 'JsonString("R")' },
            children: [],
          },
        ],
      },
    ];

    const json = generateDesignJson(project, root, [], 1);
    const parsed = JSON.parse(json) as { root: NuiNode[] };
    expect(parsed.root[0]?.componentName).toBe("NuiRow");
    expect(parsed.root[0]?.children.map((child) => child.componentName)).toEqual(["NuiButton", "NuiButton"]);
  });

  it("preserves NuiButtonSelect type and bool bind payload in save output", () => {
    const project: NuiProjectMeta = {
      name: "button_select_save",
      windowId: "BTN_SELECT_WINDOW",
      eventScript: "btn_select_ev",
    };
    const root: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Button Select Save")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiButtonSelect",
            props: {
              jLabel: 'JsonString("On/Off")',
              jValue: 'NuiBind("flag")',
            },
            children: [],
          },
        ],
      },
    ];

    const json = generateDesignJson(project, root, [], 1);
    const parsed = JSON.parse(json) as { root: NuiNode[] };
    const buttonSelectNode = parsed.root[0]?.children[0];
    expect(buttonSelectNode?.componentName).toBe("NuiButtonSelect");
    expect(buttonSelectNode?.props.jValue).toBe('NuiBind("flag")');
  });
});

describe("generateNuiResRefPack", () => {
  it("emits loader script for NuiCreateFromResRef", () => {
    const project: NuiProjectMeta = {
      name: "proj",
      windowId: "WID",
      eventScript: "ev_script",
    };
    const root: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiSpacer",
        props: {},
        children: [],
      },
    ];
    const output = generateNuiResRefPack(project, root);
    expect(output).toContain("NUI RESREF LOADER PACK");
    expect(output).toContain("FILE: nb_proj.jui");
    expect(output).toContain("NuiCreateFromResRef");
    expect(output).toContain('const string NUI_WINDOW_ID = "WID";');
    expect(output).toContain('const string NUI_EVENT_SCRIPT = "ev_script";');
    expect(output).toContain("FILE: ev_script.nss");
    expect(output).toContain('if (sEvent != "click" && sEvent != "mousedown" && sEvent != "mouseup" && sEvent != "mousescroll") return;');
    expect(output).toContain("json jPayload = NuiGetEventPayload();");

    const juiMatch = output.match(/\/\/ ===== FILE: [a-z0-9_]+\.jui =====\n([\s\S]*?)\n\n\/\/ ===== FILE:/);
    expect(juiMatch).toBeTruthy();
    const juiPayload = JSON.parse(juiMatch?.[1] ?? "{}") as {
      version?: number;
      root?: { type?: string };
      geometry?: { x?: number; y?: number; w?: number; h?: number };
    };
    expect(juiPayload.version).toBe(1);
    expect(juiPayload.root?.type).toBe("spacer");
    expect(juiPayload.geometry).toEqual({ x: -1, y: -1, w: 480, h: 320 });
  });

  it("uses preview rows for generated open-event bind init and keeps preview fields out of JUI payload", () => {
    const project: NuiProjectMeta = {
      name: "preview_proj",
      windowId: "PREVIEW_WINDOW",
      eventScript: "preview_window_ev",
    };
    const root: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("Preview List Pack")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiList",
            props: {
              jRowCount: 'NuiBind("rows_count")',
              __previewRows: '[{"row_name":"Alpha","row_value":10},{"row_name":"Beta","row_value":11}]',
              fRowHeight: "NUI_STYLE_ROW_HEIGHT",
              bBorder: "TRUE",
              nScroll: "NUI_SCROLLBARS_Y",
            },
            children: [
              {
                id: "node_3",
                componentName: "NuiListTemplateCell",
                props: { fWidth: "120.0", bVariable: "TRUE" },
                children: [
                  {
                    id: "node_4",
                    componentName: "NuiLabel",
                    props: {
                      jValue: 'NuiBind("row_name")',
                      jHAlign: "JsonInt(NUI_HALIGN_LEFT)",
                      jVAlign: "JsonInt(NUI_VALIGN_MIDDLE)",
                    },
                    children: [],
                  },
                  {
                    id: "node_5",
                    componentName: "NuiSlider",
                    props: {
                      jValue: 'NuiBind("row_value")',
                      jMin: "JsonInt(0)",
                      jMax: "JsonInt(100)",
                      jStepSize: "JsonInt(1)",
                    },
                    children: [],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const output = generateNuiResRefPack(project, root);
    expect(output).toContain('// NuiSetBind(oPC, nToken, "rows_count", JsonInt(2));');
    expect(output).toContain('// NuiSetBind(oPC, nToken, "row_name", JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonString("Alpha")), JsonString("Beta")));');
    expect(output).toContain('// NuiSetBind(oPC, nToken, "row_value", JsonArrayInsert(JsonArrayInsert(JsonArray(), JsonInt(10)), JsonInt(11)));');
    expect(output).not.toContain("__previewRows");
    expect(output).not.toContain("__previewRowsJson");
    expect(output).not.toContain("__previewBinds");

    const juiMatch = output.match(/\/\/ ===== FILE: [a-z0-9_]+\.jui =====\n([\s\S]*?)\n\n\/\/ ===== FILE:/);
    expect(juiMatch).toBeTruthy();
    const juiPayload = JSON.parse(juiMatch?.[1] ?? "{}") as {
      root?: { type?: string; row_count?: unknown };
    };
    expect(juiPayload.root?.type).toBe("list");
  });
});

describe("generateNwLivePreviewPack", () => {
  const project: NuiProjectMeta = {
    name: "test_project",
    windowId: "TEST_WINDOW",
    eventScript: "test_window_ev",
  };

  it("generates 3-script pack for in-game 1:1 preview", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiWindow",
        props: {
          jTitle: 'JsonString("My Window")',
          jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
          jResizable: "JsonBool(FALSE)",
          jCollapsed: "JsonBool(FALSE)",
          jClosable: "JsonBool(TRUE)",
          jTransparent: "JsonBool(FALSE)",
          jBorder: "JsonBool(TRUE)",
          jAcceptsInput: "JsonBool(TRUE)",
          jSizeConstraint: "JSON_NULL",
          jEdgeConstraint: "JSON_NULL",
          jFont: "JSON_STRING",
        },
        children: [
          {
            id: "node_2",
            componentName: "NuiButton",
            props: {
              jLabel: 'JsonString("Click Me")',
            },
            children: [],
          },
        ],
      },
    ];

    const pack = generateNwLivePreviewPack(project, tree, map);
    expect(pack).toContain("NWN 1:1 LIVE PREVIEW PACK");
    expect(pack).toMatch(/FILE: [a-z0-9_]+\.nss/);
    expect(pack).toContain("FILE: test_window_ev.nss");
    expect(pack.match(/FILE: [a-z0-9_]+\.nss/g)?.length).toBeGreaterThanOrEqual(3);
    expect(pack).toContain("NuiFindWindow");
    expect(pack).toContain("Build_test_project");
  });

  it("keeps event gate aligned with multi-window ids", () => {
    const map = buildComponentMap();
    const windowProps = {
      jTitle: 'JsonString("Window")',
      jGeometry: "NuiRect(-1.0, -1.0, 480.0, 320.0)",
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
    const tree: NuiNode[] = [
      { id: "node_1", componentName: "NuiWindow", props: windowProps, children: [] },
      { id: "node_2", componentName: "NuiWindow", props: windowProps, children: [] },
    ];

    const pack = generateNwLivePreviewPack(project, tree, map);
    expect(pack).toContain('if (!(sWindowId == "TEST_WINDOW" || sWindowId == "TEST_WINDOW_2")) return;');
  });
});

describe("generateAssetManifest", () => {
  it("ignores empty JsonString resrefs", () => {
    const map = buildComponentMap();
    const project: NuiProjectMeta = {
      name: "manifest_proj",
      windowId: "WID",
      eventScript: "ev_script",
    };
    const root: NuiNode[] = [
      {
        id: "node_1",
        componentName: "NuiImage",
        props: { jResRef: 'JsonString("")', jAspect: "JSON_NULL", jHAlign: "JSON_NULL", jVAlign: "JSON_NULL" },
        children: [],
      },
      {
        id: "node_2",
        componentName: "NuiImage",
        props: { jResRef: 'JsonString("icon_ok")', jAspect: "JSON_NULL", jHAlign: "JSON_NULL", jVAlign: "JSON_NULL" },
        children: [],
      },
    ];

    const manifest = generateAssetManifest(project, root, [], map);
    const jsonPart = manifest.split("\n\n# HAK staging helper")[0];
    const parsed = JSON.parse(jsonPart) as { usedResRefsInLayout: string[] };
    expect(parsed.usedResRefsInLayout).toEqual(["icon_ok"]);
  });
});

describe("swaplayout script generation", () => {
  const project: NuiProjectMeta = {
    name: "nui_project",
    windowId: "NUI_WINDOW",
    eventScript: "nui_window_ev",
  };

  function baseWindowProps() {
    return {
      jTitle: 'JsonString("Swap Test")',
      jGeometry: "NuiRect(-1.0, -1.0, 900.0, 600.0)",
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

  function buildSwapMetaNode(id: string): NuiNode {
    const swapViews = [
      {
        id: "swap_view_1_layout",
        componentName: "NuiCol",
        props: {},
        children: [
          {
            id: "swap_view_1_label",
            componentName: "NuiLabel",
            props: {
              jValue: 'JsonString("History View")',
              jHAlign: "JsonInt(NUI_HALIGN_LEFT)",
              jVAlign: "JsonInt(NUI_VALIGN_MIDDLE)",
            },
            children: [],
          },
        ],
      },
      {
        id: "swap_view_2_layout",
        componentName: "NuiCol",
        props: {},
        children: [
          {
            id: "swap_view_2_label",
            componentName: "NuiLabel",
            props: {
              jValue: 'JsonString("Ranking View")',
              jHAlign: "JsonInt(NUI_HALIGN_LEFT)",
              jVAlign: "JsonInt(NUI_VALIGN_MIDDLE)",
            },
            children: [],
          },
        ],
      },
    ];

    return {
      id: "node_swap_meta",
      componentName: "NuiId",
      props: {
        sId: `JsonString("${id}")`,
        __swap_layout_views: JSON.stringify({
          swapId: id,
          views: swapViews,
        }),
      },
      children: [
        {
          id: "node_swap_group",
          componentName: "NuiGroup",
          props: {
            bBorder: "FALSE",
            nScroll: "NUI_SCROLLBARS_NONE",
          },
          children: [{ id: "node_swap_group_child", componentName: "NuiSpacer", props: {}, children: [] }],
        },
      ],
    };
  }

  it("splits swap helper functions into event script and wires auto click routes", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_window",
        componentName: "NuiWindow",
        props: baseWindowProps(),
        children: [buildSwapMetaNode("it_duel_swap_main")],
      },
    ];

    const artifacts = generateNuiScriptOutputArtifacts(project, tree, map);
    expect(artifacts.includeCustomLib).toBe(false);
    expect(artifacts.projectScript).toContain('#include "nw_inc_nui"');
    expect(artifacts.eventScript).toContain('#include "nw_inc_nui"');
    expect(artifacts.projectScript).not.toContain("Auto-generated NuiSwapLayout view functions:");
    expect(artifacts.eventScript).toContain("Auto-generated NuiSwapLayout view functions:");
    expect(artifacts.eventScript).toContain("json NuiSwap_it_duel_swap_main_View_1()");
    expect(artifacts.eventScript).toContain("json NuiSwap_it_duel_swap_main_View_2()");
    expect(artifacts.eventScript).toContain('if (sEventElem == "it_duel_swap_main_view_1")');
    expect(artifacts.eventScript).toContain('if (sEventElem == "it_duel_swap_main_view_2")');
    expect(artifacts.eventScript).toContain(
      'NuiSetGroupLayout(oPC, nToken, "it_duel_swap_main", NuiSwap_it_duel_swap_main_View_1());',
    );
    expect(artifacts.eventScript).toContain(
      'NuiSetGroupLayout(oPC, nToken, "it_duel_swap_main", NuiSwap_it_duel_swap_main_View_2());',
    );
  });

  it("keeps lib_nui as single event include when swap + encouraged are both present", () => {
    const map = buildComponentMap();
    const tree: NuiNode[] = [
      {
        id: "node_window",
        componentName: "NuiWindow",
        props: baseWindowProps(),
        children: [
          buildSwapMetaNode("it_duel_swap_main"),
          {
            id: "node_enc_id",
            componentName: "NuiId",
            props: { sId: 'JsonString("encToggleBtn")' },
            children: [
              {
                id: "node_enc_wrap",
                componentName: "NuiEncouraged",
                props: { jEncouraged: 'NuiBind("enc_toggle_btn")' },
                children: [
                  {
                    id: "node_enc_btn",
                    componentName: "NuiButton",
                    props: { jLabel: 'JsonString("Toggle")' },
                    children: [],
                  },
                ],
              },
            ],
          },
        ],
      },
    ];

    const artifacts = generateNuiScriptOutputArtifacts(project, tree, map);
    expect(artifacts.includeCustomLib).toBe(true);
    expect(artifacts.eventScript).toContain('#include "lib_nui"');
    expect(artifacts.eventScript).not.toContain('#include "nw_inc_nui"');
    expect(artifacts.eventScript).toContain('if (sEventElem == "it_duel_swap_main_view_1")');
    expect(artifacts.eventScript).toContain('if (sEventElem == "encToggleBtn")');
  });
});
