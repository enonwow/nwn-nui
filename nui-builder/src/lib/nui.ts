import type { NuiArg, NuiAsset, NuiComponent, NuiNode, NuiProjectMeta, SlotType } from "../types";

const MULTI_CHILD_NAMES = new Set([
  "NuiWindow",
  "NuiCol",
  "NuiRow",
  "NuiGroup",
  "NuiSwapLayout",
  "NuiList",
  "NuiChart",
  "NuiDrawList",
]);

const SINGLE_CHILD_NAMES = new Set([
  "NuiId",
  "NuiWidth",
  "NuiHeight",
  "NuiAspect",
  "NuiMargin",
  "NuiPadding",
  "NuiEnabled",
  "NuiVisible",
  "NuiTooltip",
  "NuiDisabledTooltip",
  "NuiEncouraged",
  "NuiStyleForegroundColor",
  "NuiStyleFont",
  "NuiImageRegion",
  "NuiDrawListImageRegion",
  "NuiListTemplateCell",
]);

const WRAPPER_NAMES = new Set(
  [...SINGLE_CHILD_NAMES].filter((name) => name !== "NuiListTemplateCell"),
);
const VALUE_HELPERS = new Set(["NuiBind", "NuiStrRef", "NuiVec", "NuiRect", "NuiColor", "NuiComboEntry", "NuiChartSlot"]);
const IMAGE_COMPONENTS = new Set(["NuiImage", "NuiButtonImage", "NuiDrawListImage"]);
const READABLE_LAYOUT_SECTION_COMPONENTS = new Set(["NuiCol", "NuiRow", "NuiGroup"]);
const DEFAULT_ELEMENT_LABELS = ["Label 1", "Label 2", "Label 3"];
const SWAP_LAYOUT_EXPORT_META_PROP = "__swap_layout_views";
const BUILDER_VAR_STEM_PROP = "__builder_var_stem";
const PREVIEW_BIND_PROP_NAMES = ["__previewRowsJson", "__previewBinds", "__previewRows"];

interface SectionFunctionState {
  enabled: boolean;
  functionLines: string[];
  functionNameByNodeId: Map<string, string>;
  usedFunctionNames: Set<string>;
  counter: number;
}

interface NodeCodeGenContext {
  counter: number;
  stemCounters?: Record<string, number>;
  sectionFunctions?: SectionFunctionState;
  skipSectionForNodeId?: string | null;
}

export const SUPPORTED_IMAGE_EXTENSIONS = new Set(["jpg", "jpeg", "tga", "png", "gif", "webm", "wbm"]);

function splitArgs(input: string): string[] {
  const args: string[] = [];
  let current = "";
  let depth = 0;

  for (let i = 0; i < input.length; i += 1) {
    const char = input[i];
    if (char === "(") depth += 1;
    if (char === ")") depth -= 1;

    if (char === "," && depth === 0) {
      args.push(current.trim());
      current = "";
      continue;
    }
    current += char;
  }

  if (current.trim()) {
    args.push(current.trim());
  }

  return args.filter(Boolean);
}

function parseArg(rawArg: string): NuiArg {
  const [base, defaultRaw] = rawArg.split("=").map((value) => value.trim());
  const tokens = base.split(/\s+/).filter(Boolean);
  const type = tokens[0] || "json";
  const name = tokens[1] || `arg_${Math.random().toString(36).slice(2, 7)}`;

  return {
    raw: rawArg,
    type,
    name,
    defaultRaw: defaultRaw || null,
  };
}

function escapeNwString(value: string): string {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function buildJsonStringArray(labels: string[]): string {
  return labels.reduce((expr, label) => `JsonArrayInsert(${expr}, JsonString("${escapeNwString(label)}"))`, "JsonArray()");
}

function buildComboEntryArray(labels: string[]): string {
  return labels.reduce((expr, label, idx) => `JsonArrayInsert(${expr}, NuiComboEntry("${escapeNwString(label)}", ${idx}))`, "JsonArray()");
}

function getSlotType(name: string): SlotType {
  if (MULTI_CHILD_NAMES.has(name)) return "list";
  if (SINGLE_CHILD_NAMES.has(name)) return "single";
  return "none";
}

function getCategory(name: string): string {
  if (name === "NuiWindow") return "Window";
  if (name.startsWith("NuiDrawList")) return "DrawList";
  if (["NuiCol", "NuiRow", "NuiGroup", "NuiSwapLayout", "NuiSpacer", "NuiList", "NuiListTemplateCell"].includes(name))
    return "Layout";
  if (WRAPPER_NAMES.has(name)) return "Modifiers";
  if (VALUE_HELPERS.has(name)) return "Values";
  return "Components";
}

export function defaultValueFromArg(arg: NuiArg, componentName: string): string {
  if (arg.defaultRaw) return arg.defaultRaw;

  const jsonDefaultByName: Record<string, string> = {
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
    jLabel: 'JsonString("Label")',
    jValue: 'JsonString("")',
    jPlaceholder: 'JsonString("")',
    jResRef: 'JsonString("")',
    jTooltip: 'JsonString("")',
    jHAlign: "JsonInt(NUI_HALIGN_LEFT)",
    jVAlign: "JsonInt(NUI_VALIGN_MIDDLE)",
    jAspect: "JsonInt(NUI_ASPECT_FIT)",
    jBool: "JsonBool(FALSE)",
    jColor: "NuiColor(255, 255, 255, 255)",
    jRect: "NuiRect(0.0, 0.0, 120.0, 24.0)",
    jPos: "NuiVec(0.0, 0.0)",
    jCenter: "NuiVec(0.0, 0.0)",
    jA: "NuiVec(0.0, 0.0)",
    jB: "NuiVec(100.0, 100.0)",
    jCtrl0: "NuiVec(25.0, 0.0)",
    jCtrl1: "NuiVec(75.0, 100.0)",
    jRadius: "JsonFloat(32.0)",
    jLegend: 'JsonString("Legend")',
    jScissor: "NuiRect(0.0, 0.0, 512.0, 512.0)",
    jLineThickness: "JsonFloat(1.0)",
    jEnabled: "JsonBool(TRUE)",
    jFill: "JsonBool(FALSE)",
    jText: 'JsonString("")',
    jImage: "JSON_NULL",
    jRegion: "NuiRect(0.0, 0.0, 1.0, 1.0)",
    jData: "JsonArray()",
    jList: "JsonArray()",
    jSlots: "JsonArray()",
    jTemplate: "JsonArray()",
    jPoints: "JsonArray()",
  };
  const intDefaultByName: Record<string, string> = {
    nDirection: "NUI_DIRECTION_HORIZONTAL",
    nType: "NUI_CHART_TYPE_LINES",
  };

  if (arg.type === "json") {
    if (componentName === "NuiDrawList" && arg.name === "jScissor") return "JsonBool(FALSE)";
    if (componentName === "NuiVisible" && arg.name === "jVisible") return "JsonBool(TRUE)";
    if (componentName === "NuiEncouraged" && arg.name === "jEncouraged") return "JsonBool(TRUE)";
    if (componentName === "NuiButtonSelect" && arg.name === "jValue") return "JsonBool(FALSE)";
    if (componentName === "NuiOptions" && arg.name === "jValue") return "JsonInt(-1)";
    if (componentName === "NuiToggles" && arg.name === "jValue") return "JsonInt(-1)";
    if (componentName === "NuiCombo" && arg.name === "jSelected") return "JsonInt(0)";
    if (componentName === "NuiProgress" && arg.name === "jValue") return "JsonFloat(1.0)";
    if (componentName === "NuiList" && arg.name === "jRowCount") return "JsonInt(0)";
    if (componentName === "NuiSlider") {
      if (arg.name === "jValue") return "JsonInt(0)";
      if (arg.name === "jMin") return "JsonInt(0)";
      if (arg.name === "jMax") return "JsonInt(100)";
      if (arg.name === "jStepSize") return "JsonInt(1)";
    }
    if (componentName === "NuiSliderFloat") {
      if (arg.name === "jValue") return "JsonFloat(0.5)";
      if (arg.name === "jMin") return "JsonFloat(0.0)";
      if (arg.name === "jMax") return "JsonFloat(1.0)";
      if (arg.name === "jStepSize") return "JsonFloat(0.01)";
    }
    if (componentName === "NuiDrawListImage" && arg.name === "jPos") return "NuiRect(0.0, 0.0, 120.0, 24.0)";
    if (arg.name === "jElements") {
      if (componentName === "NuiCombo") return buildComboEntryArray(DEFAULT_ELEMENT_LABELS);
      return buildJsonStringArray(DEFAULT_ELEMENT_LABELS);
    }
    if (jsonDefaultByName[arg.name]) return jsonDefaultByName[arg.name];
    return "JSON_NULL";
  }
  if (arg.type === "string") {
    if (componentName === "NuiComboEntry" && arg.name === "sLabel") return '"Label 1"';
    return '""';
  }
  if (arg.type === "int") {
    if (componentName === "NuiListTemplateCell" && arg.name === "bVariable") return "TRUE";
    if (componentName === "NuiTextEdit") {
      if (arg.name === "nMaxLength") return "64";
      if (arg.name === "bMultiline") return "FALSE";
    }
    if (intDefaultByName[arg.name]) return intDefaultByName[arg.name];
    return "0";
  }
  if (arg.type === "float") return "0.0";
  return "0";
}

function parseComponentLine(signature: string): NuiComponent | null {
  const match = signature.match(/^json\s+(Nui[A-Za-z0-9_]+)\s*\((.*)\);$/);
  if (!match) return null;

  const name = match[1];
  const argsRaw = match[2].trim();
  const args = argsRaw ? splitArgs(argsRaw).map(parseArg) : [];
  const slotType = getSlotType(name);
  const structuralArgIndex = slotType === "none" ? -1 : 0;

  const defaults: Record<string, string> = {};
  args.forEach((arg, idx) => {
    if (idx === structuralArgIndex) return;
    defaults[arg.name] = defaultValueFromArg(arg, name);
  });

  return {
    name,
    signature,
    args,
    slotType,
    structuralArgIndex,
    category: getCategory(name),
    wrapper: WRAPPER_NAMES.has(name),
    lexiconUrl: `https://nwnlexicon.com/${name}`,
    defaults,
  };
}

export function parseComponentsFromText(text: string): NuiComponent[] {
  const lines = text
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);
  return lines.map(parseComponentLine).filter(Boolean) as NuiComponent[];
}

export function summarizeProps(node: NuiNode): string {
  const keys = Object.keys(node.props || {});
  if (!keys.length) return "No props";
  const short = keys.slice(0, 3).map((key) => `${key}=${String(node.props[key]).slice(0, 18)}`);
  return `${short.join(" | ")}${keys.length > 3 ? " ..." : ""}`;
}

function looksLikeExpression(value: string): boolean {
  const v = value.trim();
  if (!v) return false;
  if (v.startsWith("Json") || v.startsWith("Nui") || v.startsWith("JSON_")) return true;
  if (v === "TRUE" || v === "FALSE") return true;
  if (/^[A-Z0-9_]+$/.test(v)) return true;
  if (/^-?\d+(\.\d+)?$/.test(v)) return true;
  if (v.startsWith('"') || v.startsWith("'")) return true;
  return false;
}

function asStringLiteral(value: string): string {
  const escaped = value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
  return `"${escaped}"`;
}

function parseStrRefJsonObject(value: string): number | null {
  const match = value.trim().match(/^\{\s*"strref"\s*:\s*(-?\d+)\s*\}$/i);
  if (!match) return null;
  return Number(match[1]);
}

function normalizeVarStem(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, "_")
    .replace(/^_+|_+$/g, "");
}

function nextNodeVarName(
  node: NuiNode,
  defaultComponentName: string,
  ctx: NodeCodeGenContext,
): string {
  const stemRaw = String(node.props?.[BUILDER_VAR_STEM_PROP] ?? "");
  const stem = normalizeVarStem(stemRaw);
  if (!stem) {
    return `j_${defaultComponentName}_${ctx.counter++}`;
  }
  if (!ctx.stemCounters) {
    ctx.stemCounters = {};
  }
  const nextIndex = (ctx.stemCounters[stem] ?? 0) + 1;
  ctx.stemCounters[stem] = nextIndex;
  return `j_${stem}_${nextIndex}`;
}

function shouldExtractLayoutSection(componentName: string): boolean {
  return READABLE_LAYOUT_SECTION_COMPONENTS.has(componentName);
}

function nextSectionFunctionName(node: NuiNode, componentName: string, state: SectionFunctionState): string {
  const componentToken = normalizeVarStem(componentName) || "section";
  // Use export-local numbering instead of persisted node ids so each export starts from node_1.
  const nodeToken = `node_${state.counter++}`;
  const baseName = `BuildSection_${componentToken}_${nodeToken}`;
  if (!state.usedFunctionNames.has(baseName)) {
    state.usedFunctionNames.add(baseName);
    return baseName;
  }

  let index = 2;
  while (state.usedFunctionNames.has(`${baseName}_${index}`)) index += 1;
  const nextName = `${baseName}_${index}`;
  state.usedFunctionNames.add(nextName);
  return nextName;
}

function argExpression(arg: NuiArg, value: string | undefined, fallback: string): string {
  const v = String(value ?? "").trim();
  if (!v) return fallback;

  if (arg.type === "string") {
    if (v.startsWith('"') || v.startsWith("'")) return v;
    return asStringLiteral(v);
  }

  if (arg.type === "json") {
    const strRef = parseStrRefJsonObject(v);
    if (strRef !== null) {
      return `NuiStrRef(${strRef})`;
    }
    if (looksLikeExpression(v)) return normalizeNuiGeometryExpression(v);
    return `JsonString(${asStringLiteral(v)})`;
  }

  return v;
}

function formatExplicitDotFloatLiteral(value: number): string {
  if (!Number.isFinite(value)) return "0.0";
  if (Number.isInteger(value)) return `${Math.trunc(value)}.0`;
  const fixed = value.toFixed(6);
  const trimmed = fixed.replace(/\.?0+$/, "");
  return trimmed.includes(".") ? trimmed : `${trimmed}.0`;
}

function normalizeNumericExpressionToFloat(expression: string): string | null {
  const source = stripWrappingParens(expression.trim());
  if (!source) return null;

  const direct = parseNumericToken(source);
  if (direct !== null) return formatExplicitDotFloatLiteral(direct);

  const jsonInt = parseExprFunctionArgs(source, "JsonInt");
  if (jsonInt && jsonInt.length === 1) {
    return formatExplicitDotFloatLiteral(parseNumericExpr(jsonInt[0], "0"));
  }

  const jsonFloat = parseExprFunctionArgs(source, "JsonFloat");
  if (jsonFloat && jsonFloat.length === 1) {
    return formatExplicitDotFloatLiteral(parseNumericExpr(jsonFloat[0], "0.0"));
  }

  return null;
}

function normalizeNuiGeometryExpression(expression: string): string {
  const source = expression.trim();
  if (!source) return source;

  const rectArgs = parseExprFunctionArgs(source, "NuiRect");
  if (rectArgs && rectArgs.length === 4) {
    const normalized = rectArgs.map((part) => normalizeNumericExpressionToFloat(part) ?? stripWrappingParens(part));
    return `NuiRect(${normalized.join(", ")})`;
  }

  const vecArgs = parseExprFunctionArgs(source, "NuiVec");
  if (vecArgs && vecArgs.length === 2) {
    const normalized = vecArgs.map((part) => normalizeNumericExpressionToFloat(part) ?? stripWrappingParens(part));
    return `NuiVec(${normalized.join(", ")})`;
  }

  return source;
}

function normalizeDrawListFillArg(expression: string): string {
  const source = expression.trim();
  if (!source) return "JsonBool(FALSE)";
  if (source.startsWith("NuiBind(")) return source;

  const upper = source.toUpperCase();
  if (upper === "TRUE" || upper === "JSON_TRUE") return "JsonBool(TRUE)";
  if (upper === "FALSE" || upper === "JSON_FALSE" || upper === "JSON_NULL") return "JsonBool(FALSE)";

  const jsonBool = parseExprFunctionArgs(source, "JsonBool");
  if (jsonBool && jsonBool.length === 1) {
    return `JsonBool(${parseBoolExpr(jsonBool[0], "FALSE") ? "TRUE" : "FALSE"})`;
  }

  const jsonInt = parseExprFunctionArgs(source, "JsonInt");
  if (jsonInt && jsonInt.length === 1) {
    return `JsonBool(${parseNumericExpr(jsonInt[0], "0") !== 0 ? "TRUE" : "FALSE"})`;
  }

  const jsonFloat = parseExprFunctionArgs(source, "JsonFloat");
  if (jsonFloat && jsonFloat.length === 1) {
    return `JsonBool(${parseNumericExpr(jsonFloat[0], "0") !== 0 ? "TRUE" : "FALSE"})`;
  }

  if (source.startsWith("NuiColor(") || source.startsWith("JsonObject(") || source.startsWith("JsonObjectSet(")) {
    return "JsonBool(TRUE)";
  }

  return source;
}

function normalizeDrawListLineThicknessArg(expression: string): string {
  const source = expression.trim();
  if (!source) return "JsonFloat(1.0)";
  if (source.startsWith("NuiBind(")) return source;

  const normalized = source.toUpperCase();
  if (normalized === "JSON_NULL") return "JsonFloat(1.0)";

  const numericLiteral = parseNumericToken(source);
  if (numericLiteral !== null) {
    return `JsonFloat(${formatExplicitDotFloatLiteral(numericLiteral)})`;
  }

  const jsonInt = parseExprFunctionArgs(source, "JsonInt");
  if (jsonInt && jsonInt.length === 1) {
    return `JsonFloat(${formatExplicitDotFloatLiteral(parseNumericExpr(jsonInt[0], "0"))})`;
  }

  const jsonFloat = parseExprFunctionArgs(source, "JsonFloat");
  if (jsonFloat && jsonFloat.length === 1) {
    return `JsonFloat(${formatExplicitDotFloatLiteral(parseNumericExpr(jsonFloat[0], "0.0"))})`;
  }

  return source;
}

function normalizeDrawListPointsArg(expression: string): string {
  const source = expression.trim();
  if (!source) return "JsonArray()";
  if (source.startsWith("NuiBind(")) return source;

  const normalized = source.toUpperCase();
  if (normalized === "JSON_NULL") return "JsonArray()";

  const parsed = parseJuiExpr(source, "JsonArray()");
  if (!Array.isArray(parsed)) return source;

  const values: number[] = [];
  for (const entry of parsed) {
    if (typeof entry === "number" && Number.isFinite(entry)) {
      values.push(entry);
      continue;
    }
    if (typeof entry === "string") {
      const direct = parseNumericToken(entry.trim());
      if (direct !== null) {
        values.push(direct);
      }
      continue;
    }
    if (isJuiObject(entry)) {
      const x = typeof entry.x === "number" && Number.isFinite(entry.x) ? entry.x : null;
      const y = typeof entry.y === "number" && Number.isFinite(entry.y) ? entry.y : null;
      if (x !== null && y !== null) {
        values.push(x, y);
      }
    }
  }

  if (values.length < 2) return source;
  if (values.length % 2 !== 0) values.pop();

  let expr = "JsonArray()";
  for (const value of values) {
    expr = `JsonArrayInsert(${expr}, JsonFloat(${formatExplicitDotFloatLiteral(value)}))`;
  }
  return expr;
}

function generateNodeCodeRaw(
  node: NuiNode,
  componentMap: Map<string, NuiComponent>,
  lines: string[],
  ctx: NodeCodeGenContext,
): string {
  const component = componentMap.get(node.componentName);
  if (!component) return "JSON_NULL";

  if (component.name === "NuiDrawList") {
    const hostNode = node.children[0];
    const hostExpr = hostNode ? generateNodeCode(hostNode, componentMap, lines, ctx) : "JSON_NULL";
    const drawListVar = `jList_${ctx.counter++}`;
    lines.push(`json ${drawListVar} = JsonArray();`);
    for (const drawItem of node.children.slice(1)) {
      const drawVar = generateNodeCode(drawItem, componentMap, lines, ctx);
      lines.push(`${drawListVar} = JsonArrayInsert(${drawListVar}, ${drawVar});`);
    }

    const scissorArg = component.args.find((arg) => arg.name === "jScissor");
    const scissorFallback = scissorArg ? component.defaults[scissorArg.name] ?? defaultValueFromArg(scissorArg, component.name) : "JsonInt(0)";
    const scissorValue = scissorArg ? argExpression(scissorArg, node.props[scissorArg.name], scissorFallback) : "JsonInt(0)";

    const varName = `j_${node.componentName}_${ctx.counter++}`;
    lines.push(`json ${varName} = NuiDrawList(${hostExpr}, ${scissorValue}, ${drawListVar});`);
    return varName;
  }

  const args = component.args;
  const params: string[] = [];
  const structureIndex = component.structuralArgIndex;

  let structuralExpr: string | null = null;
  if (component.name === "NuiWindow") {
    // NWN contract: NuiWindow takes a single jRoot node (wrapper), not a JsonArray list.
    // Builder may temporarily hold multiple children; for export we normalize:
    // - 0 children: JSON_NULL
    // - 1 child: pass that child as jRoot
    // - >1 children: auto-wrap into NuiCol(jList)
    if (!node.children.length) {
      structuralExpr = "JSON_NULL";
    } else if (node.children.length === 1) {
      structuralExpr = generateNodeCode(node.children[0], componentMap, lines, ctx);
    } else {
      const listVar = `jList_${ctx.counter++}`;
      lines.push(`json ${listVar} = JsonArray();`);
      for (const child of node.children) {
        const childVar = generateNodeCode(child, componentMap, lines, ctx);
        lines.push(`${listVar} = JsonArrayInsert(${listVar}, ${childVar});`);
      }
      const colVar = `j_NuiCol_${ctx.counter++}`;
      lines.push(`json ${colVar} = NuiCol(${listVar});`);
      structuralExpr = colVar;
    }
  } else
  if (component.name === "NuiGroup") {
    // Aurora contract: NuiGroup is a single-child wrapper (children=[jChild]).
    // Builder UX allows many children, so we auto-wrap multiple children into a NuiCol.
    if (!node.children.length) {
      structuralExpr = "JSON_NULL";
    } else if (node.children.length === 1) {
      structuralExpr = generateNodeCode(node.children[0], componentMap, lines, ctx);
    } else {
      const listVar = `jList_${ctx.counter++}`;
      lines.push(`json ${listVar} = JsonArray();`);
      for (const child of node.children) {
        const childVar = generateNodeCode(child, componentMap, lines, ctx);
        lines.push(`${listVar} = JsonArrayInsert(${listVar}, ${childVar});`);
      }
      const colVar = `j_NuiCol_${ctx.counter++}`;
      lines.push(`json ${colVar} = NuiCol(${listVar});`);
      structuralExpr = colVar;
    }
  } else if (component.slotType === "list") {
    const listVar = `jList_${ctx.counter++}`;
    lines.push(`json ${listVar} = JsonArray();`);
    for (const child of node.children) {
      const childVar = generateNodeCode(child, componentMap, lines, ctx);
      lines.push(`${listVar} = JsonArrayInsert(${listVar}, ${childVar});`);
    }
    structuralExpr = listVar;
  } else if (component.slotType === "single") {
    structuralExpr = node.children[0] ? generateNodeCode(node.children[0], componentMap, lines, ctx) : "JSON_NULL";
  }

  args.forEach((arg, index) => {
    if (index === structureIndex) {
      params.push(structuralExpr ?? "JSON_NULL");
      return;
    }
    const fallback = component.defaults[arg.name] ?? defaultValueFromArg(arg, component.name);
    const current = node.props[arg.name];
    let expression = argExpression(arg, current, fallback);
    if (component.name.startsWith("NuiDrawList")) {
      if (arg.name === "jFill") {
        expression = normalizeDrawListFillArg(expression);
      } else if (arg.name === "jLineThickness") {
        expression = normalizeDrawListLineThicknessArg(expression);
      } else if (arg.name === "jPoints") {
        expression = normalizeDrawListPointsArg(expression);
      }
    }
    params.push(expression);
  });

  const varName = nextNodeVarName(node, node.componentName, ctx);
  lines.push(`json ${varName} = ${node.componentName}(${params.join(", ")});`);
  return varName;
}

function generateNodeCode(
  node: NuiNode,
  componentMap: Map<string, NuiComponent>,
  lines: string[],
  ctx: NodeCodeGenContext,
): string {
  const component = componentMap.get(node.componentName);
  if (!component) return "JSON_NULL";

  const sectionState = ctx.sectionFunctions;
  const shouldExtract =
    Boolean(sectionState?.enabled) &&
    shouldExtractLayoutSection(component.name) &&
    ctx.skipSectionForNodeId !== node.id;

  if (!shouldExtract || !sectionState) {
    return generateNodeCodeRaw(node, componentMap, lines, ctx);
  }

  const existingFnName = sectionState.functionNameByNodeId.get(node.id);
  if (existingFnName) {
    return `${existingFnName}()`;
  }

  const functionName = nextSectionFunctionName(node, component.name, sectionState);
  sectionState.functionNameByNodeId.set(node.id, functionName);

  const sectionBodyLines: string[] = [];
  const sectionCtx: NodeCodeGenContext = {
    ...ctx,
    skipSectionForNodeId: node.id,
  };
  const sectionVar = generateNodeCodeRaw(node, componentMap, sectionBodyLines, sectionCtx);

  sectionState.functionLines.push(`json ${functionName}()`);
  sectionState.functionLines.push("{");
  sectionBodyLines.forEach((line) => sectionState.functionLines.push(`    ${line}`));
  sectionState.functionLines.push(`    return ${sectionVar};`);
  sectionState.functionLines.push("}");
  sectionState.functionLines.push("");

  return `${functionName}()`;
}

function collectNuiIds(node: NuiNode, ids: string[]): void {
  if (node.componentName === "NuiId") {
    const idValue = extractStringContent(node.props.sId ?? "").trim();
    if (idValue) {
      ids.push(idValue);
    }
  }
  node.children.forEach((child) => collectNuiIds(child, ids));
}

function collectSwapGroupIds(node: NuiNode, ids: string[]): void {
  if (node.componentName === "NuiId") {
    const idValue = extractStringContent(node.props.sId ?? "").trim();
    const wrappedNode = node.children[0];
    if (idValue && wrappedNode?.componentName === "NuiGroup") {
      ids.push(idValue);
    }
  }
  node.children.forEach((child) => collectSwapGroupIds(child, ids));
}

interface EncouragedRouteSpec {
  nuiId: string;
  bindId: string;
  insideListTemplate: boolean;
  rowCountBindId: string | null;
  rowCountLiteral: number | null;
}

function collectEncouragedRouteSpecs(root: NuiNode[]): EncouragedRouteSpec[] {
  const specs: EncouragedRouteSpec[] = [];
  const seen = new Set<string>();
  interface ListContextMeta {
    rowCountBindId: string | null;
    rowCountLiteral: number | null;
  }

  const parseStaticIntExpr = (value: string): number | null => {
    const trimmed = value.trim();
    const asJsonInt = trimmed.match(/^JsonInt\(\s*(-?\d+)\s*\)$/i);
    if (asJsonInt) return Number.parseInt(asJsonInt[1], 10);
    if (/^-?\d+$/.test(trimmed)) return Number.parseInt(trimmed, 10);
    return null;
  };

  const parseListRowCountMeta = (rawValue: string | undefined): ListContextMeta => {
    const expr = String(rawValue ?? "").trim();
    if (!expr) return { rowCountBindId: null, rowCountLiteral: null };
    const bindId = extractBindIdsFromExpression(expr)[0] ?? null;
    if (bindId) return { rowCountBindId: bindId, rowCountLiteral: null };
    const literal = parseStaticIntExpr(expr);
    if (literal !== null) return { rowCountBindId: null, rowCountLiteral: Math.max(0, literal) };
    return { rowCountBindId: null, rowCountLiteral: null };
  };

  const walk = (
    node: NuiNode,
    currentNuiId: string | null,
    currentEncouragedBind: string | null,
    insideListTemplate: boolean,
    listContext: ListContextMeta | null,
  ): void => {
    const nextInsideListTemplate = insideListTemplate || node.componentName === "NuiListTemplateCell";
    let nextNuiId = currentNuiId;
    let nextEncouragedBind = currentEncouragedBind;
    let nextListContext = listContext;

    if (node.componentName === "NuiId") {
      const idValue = extractStringContent(node.props.sId ?? "").trim();
      if (idValue) nextNuiId = idValue;
    }

    if (node.componentName === "NuiEncouraged") {
      const bindId = extractBindIdsFromExpression(String(node.props.jEncouraged ?? "").trim())[0] ?? "";
      if (bindId) nextEncouragedBind = bindId;
    }

    if (node.componentName === "NuiList") {
      nextListContext = parseListRowCountMeta(node.props.jRowCount);
    }

    if (nextNuiId && nextEncouragedBind) {
      const rowCountBindId = nextInsideListTemplate ? nextListContext?.rowCountBindId ?? null : null;
      const rowCountLiteral = nextInsideListTemplate ? nextListContext?.rowCountLiteral ?? null : null;
      const key = `${nextNuiId}|${nextEncouragedBind}|${nextInsideListTemplate ? 1 : 0}|${rowCountBindId ?? ""}|${rowCountLiteral ?? ""}`;
      if (!seen.has(key)) {
        seen.add(key);
        specs.push({
          nuiId: nextNuiId,
          bindId: nextEncouragedBind,
          insideListTemplate: nextInsideListTemplate,
          rowCountBindId,
          rowCountLiteral,
        });
      }
    }

    node.children.forEach((child) => walk(child, nextNuiId, nextEncouragedBind, nextInsideListTemplate, nextListContext));
  };

  root.forEach((node) => walk(node, null, null, false, null));
  return specs;
}

interface BindUsage {
  componentName: string;
  argName: string;
  insideListTemplate: boolean;
}

const BIND_STRING_ARGS = new Set([
  "jTitle",
  "jLabel",
  "jPlaceholder",
  "jTooltip",
  "jText",
  "jFont",
  "jResRef",
]);

const BIND_BOOL_ARGS = new Set([
  "jBool",
  "jFill",
  "jEnabler",
  "jVisible",
  "jEncouraged",
  "jResizable",
  "jCollapsed",
  "jClosable",
  "jTransparent",
  "jBorder",
  "jAcceptsInput",
  "bVariable",
]);

const BIND_FLOAT_ARGS = new Set([
  "jRadius",
  "jAMin",
  "jAMax",
  "jLineThickness",
  "jMin",
  "jMax",
  "jStepSize",
  "fWidth",
  "fHeight",
  "fAspect",
  "fMargin",
  "fPadding",
]);

const BIND_INT_ARGS = new Set([
  "jSelected",
  "jValue",
  "jHAlign",
  "jVAlign",
  "jAspect",
  "nDirection",
  "nScroll",
  "nOrder",
  "nRender",
]);

const BIND_ARRAY_ARGS = new Set([
  "jElements",
  "jSlots",
  "jPoints",
  "jTemplate",
]);

const BIND_COLOR_ARGS = new Set(["jColor"]);
const BIND_RECT_ARGS = new Set(["jGeometry", "jRect", "jPos", "jScissor", "jRegion"]);
const BIND_VEC_ARGS = new Set(["jA", "jB", "jCenter", "jCtrl0", "jCtrl1"]);

function extractBindIdsFromExpression(expression: string): string[] {
  const ids: string[] = [];
  const pattern = /NuiBind\s*\(\s*"((?:\\.|[^"\\])*)"/g;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(expression)) !== null) {
    const bindId = unescapeNwString(match[1]).trim();
    if (bindId) ids.push(bindId);
  }
  return ids;
}

function isPreviewBindPayloadObject(value: unknown): value is Record<string, unknown[]> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return false;
  return Object.values(value).every((entry) => Array.isArray(entry));
}

function isPreviewRowsArray(value: unknown): value is Array<Record<string, unknown>> {
  if (!Array.isArray(value) || !value.length) return false;
  return value.every((row) => row && typeof row === "object" && !Array.isArray(row));
}

function parsePreviewRowsFromListProps(listNode: NuiNode): Record<string, unknown[]> | null {
  for (const rawKey of PREVIEW_BIND_PROP_NAMES) {
    const rawRows = String(listNode.props?.[rawKey] ?? "").trim();
    if (!rawRows) continue;
    try {
      const parsed = JSON.parse(rawRows) as unknown;
      if (isPreviewBindPayloadObject(parsed)) return parsed;
      if (isPreviewRowsArray(parsed)) {
        const out: Record<string, unknown[]> = {};
        parsed.forEach((row) => {
          for (const [bindId, rawValue] of Object.entries(row)) {
            if (!bindId) continue;
            const values = out[bindId] ?? [];
            values.push(rawValue);
            out[bindId] = values;
          }
        });
        if (Object.keys(out).length) {
          return out;
        }
      }
    } catch {
      continue;
    }
  }
  return null;
}

function collectTemplateBindIds(listNode: NuiNode): string[] {
  const bindIds = new Set<string>();
  const walk = (node: NuiNode, insideListTemplateCell: boolean): void => {
    const nextInsideListTemplateCell = insideListTemplateCell || node.componentName === "NuiListTemplateCell";
    if (nextInsideListTemplateCell) {
      for (const rawValue of Object.values(node.props || {})) {
        const value = String(rawValue ?? "").trim();
        if (!value) continue;
        const ids = extractBindIdsFromExpression(value);
        ids.forEach((id) => bindIds.add(id));
      }
    }
    node.children.forEach((child) => walk(child, nextInsideListTemplateCell));
  };

  listNode.children.forEach((child) => walk(child, false));
  return [...bindIds];
}

function collectListTemplatePreviewInitExpressions(root: NuiNode[]): Map<string, string> {
  const bindInitById = new Map<string, string>();

  const parseListRowCount = (listNode: NuiNode): string | null => {
    const rowCountExpr = String(listNode.props?.jRowCount ?? "").trim();
    return extractBindIdsFromExpression(rowCountExpr)[0] ?? null;
  };

  const formatPreviewNumber = (value: number): string => {
    const normalized = Number(value);
    if (!Number.isFinite(normalized)) return "0";
    if (Number.isInteger(normalized)) return Math.trunc(normalized).toString();
    return formatExplicitDotFloatLiteral(normalized);
  };

  const isColorLike = (value: unknown): value is { r: number; g: number; b: number; a: number } => {
    if (!value || typeof value !== "object" || Array.isArray(value)) return false;
    const color = value as Record<string, unknown>;
    const r = typeof color.r === "number" && Number.isFinite(color.r) ? Math.trunc(color.r) : null;
    const g = typeof color.g === "number" && Number.isFinite(color.g) ? Math.trunc(color.g) : null;
    const b = typeof color.b === "number" && Number.isFinite(color.b) ? Math.trunc(color.b) : null;
    const aRaw = color.a === undefined ? 255 : typeof color.a === "number" && Number.isFinite(color.a) ? Math.trunc(color.a) : null;
    return r !== null && g !== null && b !== null && aRaw !== null;
  };

  const valueToExpr = (value: unknown): string => {
    if (value === null || value === undefined) return "JSON_NULL";
    if (typeof value === "string") return `JsonString(${asStringLiteral(value)})`;
    if (typeof value === "boolean") return `JsonBool(${value ? "TRUE" : "FALSE"})`;
    if (typeof value === "number") {
      if (Number.isInteger(value)) return `JsonInt(${formatPreviewNumber(value)})`;
      return `JsonFloat(${formatPreviewNumber(value)})`;
    }
    if (isColorLike(value)) {
      return `NuiColor(${value.r}, ${value.g}, ${value.b}, ${value.a})`;
    }
    if (Array.isArray(value)) {
      let expr = "JsonArray()";
      for (const entry of value) {
        expr = `JsonArrayInsert(${expr}, ${valueToExpr(entry)})`;
      }
      return expr;
    }
    return "JSON_NULL";
  };

  const buildArrayExpr = (values: unknown[]): string => {
    let expr = "JsonArray()";
    for (const value of values) {
      expr = `JsonArrayInsert(${expr}, ${valueToExpr(value)})`;
    }
    return expr;
  };

  const walk = (node: NuiNode): void => {
    if (node.componentName === "NuiList") {
      const rowCountBindId = parseListRowCount(node);
      const previewRows = parsePreviewRowsFromListProps(node);
      const templateBindIds = collectTemplateBindIds(node);
      const rowCountFromRows = previewRows
        ? Object.values(previewRows).reduce((acc, values) => Math.max(acc, values.length), 0)
        : 0;

      if (rowCountBindId) {
        bindInitById.set(rowCountBindId, `JsonInt(${rowCountFromRows})`);
      }

      templateBindIds.forEach((bindId) => {
        const values = previewRows?.[bindId];
        if (!values || !values.length) {
          bindInitById.set(bindId, "JsonArray()");
          return;
        }
        bindInitById.set(bindId, buildArrayExpr(values));
      });
    }

    node.children.forEach(walk);
  };

  root.forEach(walk);
  return bindInitById;
}

function collectBindUsagesMap(root: NuiNode[]): Map<string, BindUsage[]> {
  const usageMap = new Map<string, BindUsage[]>();

  const walk = (node: NuiNode, insideListTemplate: boolean): void => {
    const nextInsideListTemplate = insideListTemplate || node.componentName === "NuiListTemplateCell";

    for (const [argName, rawValue] of Object.entries(node.props || {})) {
      const value = String(rawValue ?? "").trim();
      if (!value) continue;
      const bindIds = extractBindIdsFromExpression(value);
      bindIds.forEach((bindId) => {
        const usageList = usageMap.get(bindId) ?? [];
        usageList.push({
          componentName: node.componentName,
          argName,
          insideListTemplate: nextInsideListTemplate,
        });
        usageMap.set(bindId, usageList);
      });
    }

    node.children.forEach((child) => walk(child, nextInsideListTemplate));
  };

  root.forEach((node) => walk(node, false));
  return usageMap;
}

function inferBindInitExpression(
  bindId: string,
  usages: BindUsage[],
  listTemplatePreviewInitExpressions?: Map<string, string>,
): string {
  const override = listTemplatePreviewInitExpressions?.get(bindId);
  if (override) return override;

  if (!usages.length) return "JSON_NULL";

  const outsideTemplateUsages = usages.filter((usage) => !usage.insideListTemplate);
  if (!outsideTemplateUsages.length) {
    // NuiList template bindings expect arrays-of-values.
    return "JsonArray()";
  }

  const inferForUsage = (usage: BindUsage): string | null => {
    const componentName = usage.componentName;
    const argName = usage.argName;

    if (componentName === "NuiList" && argName === "jRowCount") {
      return "JsonInt(0)";
    }

    if (componentName === "NuiOptions" && argName === "jValue") {
      return "JsonInt(-1)";
    }
    if (componentName === "NuiToggles" && argName === "jValue") {
      return "JsonInt(-1)";
    }
    if (componentName === "NuiProgress" && argName === "jValue") {
      return "JsonFloat(0.0)";
    }
    if (componentName === "NuiSliderFloat" && (argName === "jValue" || argName === "jMin" || argName === "jMax" || argName === "jStepSize")) {
      return "JsonFloat(0.0)";
    }
    if (componentName === "NuiSlider" && (argName === "jValue" || argName === "jMin" || argName === "jMax" || argName === "jStepSize")) {
      return "JsonInt(0)";
    }
    if (componentName === "NuiButtonSelect" && argName === "jValue") {
      return "JsonBool(FALSE)";
    }
    if (componentName === "NuiCheck" && argName === "jBool") {
      return "JsonBool(FALSE)";
    }
    if (componentName === "NuiColorPicker" && argName === "jColor") {
      return "NuiColor(255, 255, 255, 255)";
    }
    if ((componentName === "NuiLabel" || componentName === "NuiText") && argName === "jValue") {
      return 'JsonString("")';
    }
    if (componentName === "NuiTextEdit" && (argName === "jValue" || argName === "jPlaceholder")) {
      return 'JsonString("")';
    }

    if (BIND_ARRAY_ARGS.has(argName)) return "JsonArray()";
    if (BIND_RECT_ARGS.has(argName)) return "NuiRect(0.0, 0.0, 0.0, 0.0)";
    if (BIND_VEC_ARGS.has(argName)) return "NuiVec(0.0, 0.0)";
    if (BIND_COLOR_ARGS.has(argName)) return "NuiColor(255, 255, 255, 255)";
    if (BIND_STRING_ARGS.has(argName)) return 'JsonString("")';
    if (BIND_BOOL_ARGS.has(argName)) return "JsonBool(FALSE)";
    if (BIND_FLOAT_ARGS.has(argName)) return "JsonFloat(0.0)";
    if (BIND_INT_ARGS.has(argName)) return "JsonInt(0)";

    if (argName.startsWith("j")) return "JSON_NULL";
    if (argName.startsWith("f")) return "JsonFloat(0.0)";
    if (argName.startsWith("n")) return "JsonInt(0)";
    if (argName.startsWith("b")) return "JsonBool(FALSE)";
    if (argName.startsWith("s")) return 'JsonString("")';

    return null;
  };

  const inferredOutside = outsideTemplateUsages.map(inferForUsage).find((value) => Boolean(value));
  if (inferredOutside) {
    return inferredOutside;
  }

  if (usages.some((usage) => usage.componentName === "NuiList" && usage.argName === "jRowCount")) {
    return "JsonInt(0)";
  }

  if (usages.some((usage) => usage.insideListTemplate)) {
    return "JsonArray()";
  }

  if (usages.some((usage) => usage.componentName === "NuiProgress" && usage.argName === "jValue")) {
    return "JsonFloat(0.0)";
  }

  return "JSON_NULL";
}

function buildBindInitOpenBlockLines(
  bindUsages: Map<string, BindUsage[]>,
  eventVarName: string,
  indent: string,
  activeInitLines: string[] = [],
  listTemplatePreviewInitExpressions?: Map<string, string>,
): string[] {
  if (!bindUsages.size && !activeInitLines.length) return [];

  const bindIds = [...bindUsages.keys()].sort((a, b) => a.localeCompare(b));
  const hasTemplateBinds = bindIds.some((bindId) =>
    (bindUsages.get(bindId) ?? []).some((usage) => usage.insideListTemplate),
  );

  const lines: string[] = [];
  lines.push(`${indent}if (${eventVarName} == "open")`);
  lines.push(`${indent}{`);
  lines.push(`${indent}    // Auto-generated bind init stubs.`);
  lines.push(`${indent}    // Uncomment + adjust values to initialize your NuiBind(...) data on window open.`);
  if (hasTemplateBinds) {
    lines.push(`${indent}    // NOTE: binds used in NuiListTemplateCell usually need JsonArray() with row values.`);
  }
  bindIds.forEach((bindId) => {
    const initExpr = inferBindInitExpression(bindId, bindUsages.get(bindId) ?? [], listTemplatePreviewInitExpressions);
    lines.push(`${indent}    // NuiSetBind(oPC, nToken, "${escapeNwString(bindId)}", ${initExpr});`);
  });
  if (activeInitLines.length) {
    lines.push(`${indent}    // Auto-generated required init for bind-driven interaction routes.`);
    activeInitLines.forEach((line) => lines.push(line));
  }
  lines.push(`${indent}    return;`);
  lines.push(`${indent}}`);
  lines.push("");
  return lines;
}

function encouragedRowBindKey(bindId: string): string {
  const safe = bindId
    .trim()
    .replace(/[^A-Za-z0-9_]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_+|_+$/g, "");
  return safe ? `__enc_row_${safe}` : "__enc_row";
}

function buildEncouragedRowCountResolveLines(
  spec: EncouragedRouteSpec,
  ordinal: number,
  indent: string,
): { lines: string[]; rowCountVarName: string } {
  const rowCountVarName = `nEncRowCount${ordinal}`;
  const lines: string[] = [];
  if (spec.rowCountBindId) {
    const rowCountJsonVarName = `jEncRowCount${ordinal}`;
    lines.push(
      `${indent}json ${rowCountJsonVarName} = NuiLib_GetBindOrDefault(oPC, nToken, "${escapeNwString(spec.rowCountBindId)}", JsonInt(0));`,
    );
    lines.push(`${indent}int ${rowCountVarName} = JsonGetInt(${rowCountJsonVarName});`);
  } else if (typeof spec.rowCountLiteral === "number") {
    lines.push(`${indent}int ${rowCountVarName} = ${Math.max(0, Math.trunc(spec.rowCountLiteral))};`);
  } else {
    lines.push(`${indent}int ${rowCountVarName} = 0;`);
  }
  return { lines, rowCountVarName };
}

function buildEncouragedClickRouteLines(
  routeSpecs: EncouragedRouteSpec[],
  eventElementVarName: string,
  eventRowVarName: string,
  indent: string,
): string[] {
  if (!routeSpecs.length) return [];

  const grouped = new Map<string, EncouragedRouteSpec[]>();
  routeSpecs.forEach((spec) => {
    const bucket = grouped.get(spec.nuiId) ?? [];
    bucket.push(spec);
    grouped.set(spec.nuiId, bucket);
  });

  const lines: string[] = [];
  [...grouped.keys()]
    .sort((a, b) => a.localeCompare(b))
    .forEach((nuiId) => {
      const specsForId = grouped.get(nuiId) ?? [];
      lines.push(`${indent}if (${eventElementVarName} == "${escapeNwString(nuiId)}")`);
      lines.push(`${indent}{`);
      lines.push(`${indent}    // Auto-generated NuiEncouraged bind sync.`);
      specsForId.forEach((spec, specIndex) => {
        if (spec.insideListTemplate) {
          const ordinal = specIndex + 1;
          const { lines: rowCountLines, rowCountVarName } = buildEncouragedRowCountResolveLines(spec, ordinal, `${indent}    `);
          lines.push(...rowCountLines);
          const rowBindKey = encouragedRowBindKey(spec.bindId);
          lines.push(
            `${indent}    NuiLib_EncouragedToggleRow(oPC, nToken, ${eventRowVarName}, ${rowCountVarName}, "${escapeNwString(spec.bindId)}", "${escapeNwString(rowBindKey)}");`,
          );
        } else {
          const encVar = `jEncCurrent${specIndex + 1}`;
          const boolVar = `bEncCurrent${specIndex + 1}`;
          lines.push(`${indent}    json ${encVar} = NuiLib_GetBindOrDefault(oPC, nToken, "${escapeNwString(spec.bindId)}", JsonBool(FALSE));`);
          lines.push(`${indent}    int ${boolVar} = JsonGetInt(${encVar});`);
          lines.push(`${indent}    NuiLib_SetBindSafe(oPC, nToken, "${escapeNwString(spec.bindId)}", JsonBool(!${boolVar}));`);
        }
      });
      lines.push(`${indent}    return;`);
      lines.push(`${indent}}`);
    });

  return lines;
}

function buildEncouragedOpenInitLines(routeSpecs: EncouragedRouteSpec[], indent: string): string[] {
  if (!routeSpecs.length) return [];

  const lines: string[] = [];
  const seen = new Set<string>();
  let initOrdinal = 0;
  routeSpecs.forEach((spec) => {
    const bindKey = spec.insideListTemplate
      ? `${spec.bindId}|1|${spec.rowCountBindId ?? ""}|${spec.rowCountLiteral ?? ""}`
      : `${spec.bindId}|0`;
    if (seen.has(bindKey)) return;
    seen.add(bindKey);
    initOrdinal += 1;

    if (spec.insideListTemplate) {
      const { lines: rowCountLines, rowCountVarName } = buildEncouragedRowCountResolveLines(spec, initOrdinal, indent);
      lines.push(...rowCountLines);
      const encVar = `jEncInit${initOrdinal}`;
      const encLenVar = `nEncInitLen${initOrdinal}`;
      const encLoopVar = `iEncInit${initOrdinal}`;
      lines.push(`${indent}json ${encVar} = NuiGetBind(oPC, nToken, "${escapeNwString(spec.bindId)}");`);
      lines.push(`${indent}if (JsonGetType(${encVar}) != JSON_TYPE_ARRAY)`);
      lines.push(`${indent}{`);
      lines.push(`${indent}    ${encVar} = JsonArray();`);
      lines.push(`${indent}}`);
      lines.push(`${indent}int ${encLenVar} = JsonGetLength(${encVar});`);
      lines.push(`${indent}int ${encLoopVar};`);
      lines.push(`${indent}for (${encLoopVar} = ${encLenVar}; ${encLoopVar} < ${rowCountVarName}; ${encLoopVar}++)`);
      lines.push(`${indent}{`);
      lines.push(`${indent}    ${encVar} = JsonArrayInsert(${encVar}, JsonBool(FALSE));`);
      lines.push(`${indent}}`);
      lines.push(`${indent}NuiSetBind(oPC, nToken, "${escapeNwString(spec.bindId)}", ${encVar});`);
      const rowBindKey = encouragedRowBindKey(spec.bindId);
      lines.push(`${indent}if (JsonGetType(NuiGetBind(oPC, nToken, "${escapeNwString(rowBindKey)}")) == JSON_TYPE_NULL)`);
      lines.push(`${indent}{`);
      lines.push(`${indent}    NuiSetBind(oPC, nToken, "${escapeNwString(rowBindKey)}", JsonNull());`);
      lines.push(`${indent}}`);
    } else {
      lines.push(`${indent}if (JsonGetType(NuiGetBind(oPC, nToken, "${escapeNwString(spec.bindId)}")) == JSON_TYPE_NULL)`);
      lines.push(`${indent}{`);
      lines.push(`${indent}    NuiSetBind(oPC, nToken, "${escapeNwString(spec.bindId)}", JsonBool(FALSE));`);
      lines.push(`${indent}}`);
    }
  });

  return lines;
}

interface SwapLayoutExportMeta {
  version?: number;
  swapId?: string;
  views?: NuiNode[];
}

interface SwapRouteSpec {
  swapId: string;
  triggerId: string;
  functionName: string;
  layoutNode: NuiNode;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function cloneNuiNodeFromUnknown(value: unknown): NuiNode | null {
  if (!isRecord(value)) return null;
  const id = typeof value.id === "string" ? value.id : "";
  const componentName = typeof value.componentName === "string" ? value.componentName : "";
  const propsRaw = value.props;
  const childrenRaw = value.children;
  if (!id || !componentName || !isRecord(propsRaw) || !Array.isArray(childrenRaw)) return null;

  const props: Record<string, string> = {};
  for (const [key, propValue] of Object.entries(propsRaw)) {
    if (typeof propValue !== "string") return null;
    props[key] = propValue;
  }

  const children: NuiNode[] = [];
  for (const child of childrenRaw) {
    const parsedChild = cloneNuiNodeFromUnknown(child);
    if (!parsedChild) return null;
    children.push(parsedChild);
  }

  return {
    id,
    componentName,
    props,
    children,
  };
}

function sanitizeSwapToken(value: string, fallback: string): string {
  const normalized = value
    .trim()
    .replace(/[^A-Za-z0-9_]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_+|_+$/g, "");
  return normalized || fallback;
}

function uniqueToken(seed: string, used: Set<string>): string {
  if (!used.has(seed)) {
    used.add(seed);
    return seed;
  }
  let index = 2;
  while (used.has(`${seed}_${index}`)) index += 1;
  const next = `${seed}_${index}`;
  used.add(next);
  return next;
}

function parseSwapLayoutMeta(raw: string | undefined): SwapLayoutExportMeta | null {
  const value = String(raw ?? "").trim();
  if (!value) return null;
  try {
    const parsed = JSON.parse(value) as unknown;
    if (!isRecord(parsed)) return null;
    return parsed as SwapLayoutExportMeta;
  } catch {
    return null;
  }
}

function collectSwapRouteSpecs(root: NuiNode[]): SwapRouteSpec[] {
  const usedTriggers = new Set<string>();
  const usedFunctions = new Set<string>();
  const specs: SwapRouteSpec[] = [];

  const walk = (node: NuiNode): void => {
    if (node.componentName === "NuiId") {
      const meta = parseSwapLayoutMeta(node.props[SWAP_LAYOUT_EXPORT_META_PROP]);
      const rawViews = Array.isArray(meta?.views) ? meta?.views : [];
      if (rawViews && rawViews.length) {
        const parsedViews = rawViews.map((candidate) => cloneNuiNodeFromUnknown(candidate)).filter(Boolean) as NuiNode[];
        if (parsedViews.length) {
          const fallbackSwapId = extractStringContent(node.props.sId ?? "").trim() || "swap_main";
          const swapId = sanitizeSwapToken(String(meta?.swapId ?? fallbackSwapId), "swap_main");
          parsedViews.forEach((layoutNode, index) => {
            const triggerSeed = sanitizeSwapToken(`${swapId}_view_${index + 1}`, `swap_view_${index + 1}`);
            const functionSeed = sanitizeSwapToken(`NuiSwap_${swapId}_View_${index + 1}`, `NuiSwap_View_${index + 1}`);
            const triggerId = uniqueToken(triggerSeed, usedTriggers);
            const functionName = uniqueToken(functionSeed, usedFunctions);
            specs.push({
              swapId,
              triggerId,
              functionName,
              layoutNode,
            });
          });
        }
      }
    }
    node.children.forEach(walk);
  };

  root.forEach(walk);
  return specs;
}

function buildSwapLayoutFunctionLines(specs: SwapRouteSpec[], componentMap: Map<string, NuiComponent>): string[] {
  const lines: string[] = [];
  for (const spec of specs) {
    lines.push(`json ${spec.functionName}()`);
    lines.push("{");
    const functionLines: string[] = [];
    const functionCtx = { counter: 1 };
    const topVar = generateNodeCode(spec.layoutNode, componentMap, functionLines, functionCtx);
    functionLines.forEach((line) => lines.push(`    ${line}`));
    lines.push(`    return ${topVar};`);
    lines.push("}");
    lines.push("");
  }
  return lines;
}

function extractStringContent(value: string): string {
  const v = String(value ?? "").trim();
  const jsonMatch = v.match(/^JsonString\("((?:\\.|[^"\\])*)"\)$/);
  if (jsonMatch) return unescapeNwString(jsonMatch[1]);
  const quoteMatch = v.match(/^"((?:\\.|[^"\\])*)"$/);
  if (quoteMatch) return unescapeNwString(quoteMatch[1]);
  return v;
}

function unescapeNwString(value: string): string {
  let out = "";
  for (let i = 0; i < value.length; i += 1) {
    const ch = value[i];
    if (ch !== "\\" || i + 1 >= value.length) {
      out += ch;
      continue;
    }

    const next = value[i + 1];
    i += 1;
    if (next === "n") {
      out += "\n";
    } else if (next === "r") {
      out += "\r";
    } else if (next === "t") {
      out += "\t";
    } else if (next === "\\" || next === '"') {
      out += next;
    } else {
      out += next;
    }
  }
  return out;
}

function collectImageResRefs(node: NuiNode, componentMap: Map<string, NuiComponent>, out: string[]): void {
  if (IMAGE_COMPONENTS.has(node.componentName)) {
    const component = componentMap.get(node.componentName);
    const resArg = component?.args.find((arg) => arg.name === "jResRef");
    if (resArg) {
      out.push(extractStringContent(node.props[resArg.name] ?? ""));
    }
  }

  node.children.forEach((child) => collectImageResRefs(child, componentMap, out));
}

function buildWindowIds(baseWindowId: string, root: NuiNode[]): string[] {
  const base = baseWindowId.trim() || "NUI_WINDOW";
  const ids: string[] = [];
  let windowIndex = 0;
  for (const node of root) {
    if (node.componentName !== "NuiWindow") continue;
    windowIndex += 1;
    ids.push(windowIndex === 1 ? base : `${base}_${windowIndex}`);
  }
  return ids;
}

function windowIdConditionExpr(windowIds: string[]): string {
  if (!windowIds.length) return "FALSE";
  return windowIds.map((id) => `sWindowId == "${id}"`).join(" || ");
}

export function generateDesignJson(
  project: NuiProjectMeta,
  root: NuiNode[],
  assets: NuiAsset[],
  componentCount: number,
): string {
  return JSON.stringify(
    {
      project: {
        name: project.name.trim(),
        windowId: project.windowId.trim(),
        eventScript: project.eventScript.trim(),
        mergeScripts: project.mergeScripts === true,
      },
      root,
      assets,
      componentCount,
    },
    null,
    2,
  );
}

function toNwScriptIdentifier(value: string, fallback: string): string {
  const normalized = value
    .trim()
    .replace(/[^A-Za-z0-9_]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_+|_+$/g, "");
  const safe = normalized || fallback;
  const prefixed = /^[0-9]/.test(safe) ? `n_${safe}` : safe;
  return prefixed.slice(0, 48);
}

type JuiArray = JuiValue[];
interface JuiObject {
  [key: string]: JuiValue;
}
type JuiValue = null | boolean | number | string | JuiObject | JuiArray;

const NUI_NUMERIC_CONSTANTS: Record<string, number> = {
  NUI_DIRECTION_HORIZONTAL: 0,
  NUI_DIRECTION_VERTICAL: 1,
  NUI_SCROLLBARS_NONE: 0,
  NUI_SCROLLBARS_X: 1,
  NUI_SCROLLBARS_Y: 2,
  NUI_SCROLLBARS_BOTH: 3,
  NUI_SCROLLBARS_AUTO: 4,
  NUI_ASPECT_FIT: 0,
  NUI_ASPECT_FILL: 1,
  NUI_ASPECT_FIT100: 2,
  NUI_ASPECT_EXACT: 3,
  NUI_ASPECT_EXACTSCALED: 4,
  NUI_ASPECT_STRETCH: 5,
  NUI_HALIGN_CENTER: 0,
  NUI_HALIGN_LEFT: 1,
  NUI_HALIGN_RIGHT: 2,
  NUI_VALIGN_MIDDLE: 0,
  NUI_VALIGN_TOP: 1,
  NUI_VALIGN_BOTTOM: 2,
  NUI_STYLE_PRIMARY_WIDTH: 150.0,
  NUI_STYLE_PRIMARY_HEIGHT: 50.0,
  NUI_STYLE_SECONDARY_WIDTH: 150.0,
  NUI_STYLE_SECONDARY_HEIGHT: 35.0,
  NUI_STYLE_TERTIARY_WIDTH: 100.0,
  NUI_STYLE_TERTIARY_HEIGHT: 30.0,
  NUI_STYLE_ROW_HEIGHT: 25.0,
  NUI_NUMBER_FLAG_HEX: 0x001,
  NUI_TEXT_FLAG_LOWERCASE: 0x001,
  NUI_TEXT_FLAG_UPPERCASE: 0x002,
  NUI_CHART_TYPE_LINES: 0,
  NUI_CHART_TYPE_COLUMN: 1,
  NUI_DRAW_LIST_ITEM_TYPE_POLYLINE: 0,
  NUI_DRAW_LIST_ITEM_TYPE_CURVE: 1,
  NUI_DRAW_LIST_ITEM_TYPE_CIRCLE: 2,
  NUI_DRAW_LIST_ITEM_TYPE_ARC: 3,
  NUI_DRAW_LIST_ITEM_TYPE_TEXT: 4,
  NUI_DRAW_LIST_ITEM_TYPE_IMAGE: 5,
  NUI_DRAW_LIST_ITEM_TYPE_LINE: 6,
  NUI_DRAW_LIST_ITEM_TYPE_RECT: 7,
  NUI_DRAW_LIST_ITEM_ORDER_BEFORE: -1,
  NUI_DRAW_LIST_ITEM_ORDER_AFTER: 1,
  NUI_DRAW_LIST_ITEM_RENDER_ALWAYS: 0,
  NUI_DRAW_LIST_ITEM_RENDER_MOUSE_OFF: 1,
  NUI_DRAW_LIST_ITEM_RENDER_MOUSE_HOVER: 2,
  NUI_DRAW_LIST_ITEM_RENDER_MOUSE_LEFT: 3,
  NUI_DRAW_LIST_ITEM_RENDER_MOUSE_RIGHT: 4,
  NUI_DRAW_LIST_ITEM_RENDER_MOUSE_MIDDLE: 5,
};

function isJuiObject(value: JuiValue): value is JuiObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function stripWrappingParens(raw: string): string {
  let value = raw.trim();
  while (value.startsWith("(") && value.endsWith(")")) {
    let depth = 0;
    let validWrap = true;
    for (let i = 0; i < value.length; i += 1) {
      const ch = value[i];
      if (ch === "(") depth += 1;
      if (ch === ")") depth -= 1;
      if (depth === 0 && i < value.length - 1) {
        validWrap = false;
        break;
      }
      if (depth < 0) {
        validWrap = false;
        break;
      }
    }
    if (!validWrap || depth !== 0) break;
    value = value.slice(1, -1).trim();
  }
  return value;
}

function hasBalancedExprParentheses(value: string): boolean {
  let depth = 0;
  let inDoubleQuote = false;

  for (let i = 0; i < value.length; i += 1) {
    const ch = value[i];
    const prev = i > 0 ? value[i - 1] : "";
    if (ch === '"' && prev !== "\\") {
      inDoubleQuote = !inDoubleQuote;
      continue;
    }
    if (inDoubleQuote) continue;
    if (ch === "(") depth += 1;
    if (ch === ")") {
      depth -= 1;
      if (depth < 0) return false;
    }
  }

  return depth === 0 && !inDoubleQuote;
}

function splitTopLevelExprArgs(input: string): string[] {
  const args: string[] = [];
  let current = "";
  let depth = 0;
  let inDoubleQuote = false;

  for (let i = 0; i < input.length; i += 1) {
    const ch = input[i];
    const prev = i > 0 ? input[i - 1] : "";
    if (ch === '"' && prev !== "\\") {
      inDoubleQuote = !inDoubleQuote;
      current += ch;
      continue;
    }
    if (!inDoubleQuote) {
      if (ch === "(") depth += 1;
      if (ch === ")") depth = Math.max(0, depth - 1);
      if (ch === "," && depth === 0) {
        args.push(current.trim());
        current = "";
        continue;
      }
    }
    current += ch;
  }

  if (current.trim()) args.push(current.trim());
  return args;
}

function parseExprFunctionArgs(raw: string, functionName: string): string[] | null {
  const value = raw.trim();
  const prefix = `${functionName}(`;
  if (!value.startsWith(prefix) || !value.endsWith(")")) return null;
  const inner = value.slice(prefix.length, -1);
  if (!hasBalancedExprParentheses(inner)) return null;
  return splitTopLevelExprArgs(inner);
}

function parseQuotedLiteral(raw: string): string | null {
  const match = raw.trim().match(/^"((?:\\.|[^"\\])*)"$/);
  if (!match) return null;
  return unescapeNwString(match[1]);
}

function parseStringExpr(raw: string | undefined, fallback: string): string {
  const source = String(raw ?? "").trim() || fallback;
  const quoted = parseQuotedLiteral(source);
  if (quoted !== null) return quoted;

  const jsonStr = parseExprFunctionArgs(source, "JsonString");
  if (jsonStr && jsonStr.length === 1) {
    const inner = parseQuotedLiteral(jsonStr[0]);
    if (inner !== null) return inner;
    return stripWrappingParens(jsonStr[0]);
  }

  return stripWrappingParens(source);
}

function parseBoolExpr(raw: string | undefined, fallback: string): boolean {
  const source = stripWrappingParens(String(raw ?? "").trim() || fallback);
  const normalized = source.toUpperCase();
  if (normalized === "TRUE" || normalized === "1" || normalized === "JSON_TRUE") return true;
  if (normalized === "FALSE" || normalized === "0" || normalized === "JSON_FALSE") return false;

  const jsonBool = parseExprFunctionArgs(source, "JsonBool");
  if (jsonBool && jsonBool.length === 1) {
    return parseBoolExpr(jsonBool[0], "FALSE");
  }

  return false;
}

function parseNumericToken(raw: string): number | null {
  const source = stripWrappingParens(raw);
  if (!source) return null;
  if (/^-?(?:\d+(?:\.\d+)?|\.\d+)$/.test(source)) return Number(source);
  if (/^-?0x[0-9a-f]+$/i.test(source)) return Number.parseInt(source, 16);

  const normalized = source.toUpperCase();
  if (Object.prototype.hasOwnProperty.call(NUI_NUMERIC_CONSTANTS, normalized)) {
    return NUI_NUMERIC_CONSTANTS[normalized];
  }

  return null;
}

function parseNumericExpr(raw: string | undefined, fallback: string): number {
  const source = stripWrappingParens(String(raw ?? "").trim() || fallback);

  const jsonInt = parseExprFunctionArgs(source, "JsonInt");
  if (jsonInt && jsonInt.length === 1) {
    return parseNumericExpr(jsonInt[0], "0");
  }
  const jsonFloat = parseExprFunctionArgs(source, "JsonFloat");
  if (jsonFloat && jsonFloat.length === 1) {
    return parseNumericExpr(jsonFloat[0], "0");
  }

  const parts = source
    .split("|")
    .map((part) => part.trim())
    .filter(Boolean);
  if (parts.length > 1) {
    let mask = 0;
    for (const part of parts) {
      const parsed = parseNumericToken(part);
      if (parsed === null) return 0;
      mask |= Math.trunc(parsed);
    }
    return mask;
  }

  const literal = parseNumericToken(source);
  return literal === null ? 0 : literal;
}

function parseJuiExpr(raw: string | undefined, fallback: string): JuiValue {
  const source = stripWrappingParens(String(raw ?? "").trim() || fallback);
  if (!source) return null;

  const quoted = parseQuotedLiteral(source);
  if (quoted !== null) return quoted;

  const upper = source.toUpperCase();
  if (upper === "JSON_NULL") return null;
  if (upper === "JSON_TRUE") return true;
  if (upper === "JSON_FALSE") return false;
  if (upper === "JSON_STRING") return "";
  if (upper === "TRUE") return true;
  if (upper === "FALSE") return false;

  const jsonNull = parseExprFunctionArgs(source, "JsonNull");
  if (jsonNull && jsonNull.length === 0) return null;
  const jsonString = parseExprFunctionArgs(source, "JsonString");
  if (jsonString && jsonString.length === 1) {
    return parseStringExpr(jsonString[0], "");
  }
  const jsonBool = parseExprFunctionArgs(source, "JsonBool");
  if (jsonBool && jsonBool.length === 1) {
    return parseBoolExpr(jsonBool[0], "FALSE");
  }
  const jsonInt = parseExprFunctionArgs(source, "JsonInt");
  if (jsonInt && jsonInt.length === 1) {
    return parseNumericExpr(jsonInt[0], "0");
  }
  const jsonFloat = parseExprFunctionArgs(source, "JsonFloat");
  if (jsonFloat && jsonFloat.length === 1) {
    return parseNumericExpr(jsonFloat[0], "0");
  }
  const jsonArray = parseExprFunctionArgs(source, "JsonArray");
  if (jsonArray && jsonArray.length === 0) return [];
  const jsonArrayInsert = parseExprFunctionArgs(source, "JsonArrayInsert");
  if (jsonArrayInsert && jsonArrayInsert.length === 2) {
    const base = parseJuiExpr(jsonArrayInsert[0], "JsonArray()");
    const item = parseJuiExpr(jsonArrayInsert[1], "JSON_NULL");
    const out = Array.isArray(base) ? [...base] : [];
    out.push(item);
    return out;
  }
  const jsonObject = parseExprFunctionArgs(source, "JsonObject");
  if (jsonObject && jsonObject.length === 0) return {};
  const jsonObjectSet = parseExprFunctionArgs(source, "JsonObjectSet");
  if (jsonObjectSet && jsonObjectSet.length === 3) {
    const base = parseJuiExpr(jsonObjectSet[0], "JsonObject()");
    const key = parseStringExpr(jsonObjectSet[1], '""');
    const value = parseJuiExpr(jsonObjectSet[2], "JSON_NULL");
    const out: JuiObject = isJuiObject(base) ? { ...base } : {};
    out[key] = value;
    return out;
  }
  const nuiBind = parseExprFunctionArgs(source, "NuiBind");
  if (nuiBind && nuiBind.length >= 1) {
    return {
      bind: parseStringExpr(nuiBind[0], '"bind"'),
      number_flags: parseNumericExpr(nuiBind[1], "0"),
      number_precision: parseNumericExpr(nuiBind[2], "0"),
      text_flags: parseNumericExpr(nuiBind[3], "0"),
    };
  }
  const nuiStrRef = parseExprFunctionArgs(source, "NuiStrRef");
  if (nuiStrRef && nuiStrRef.length === 1) {
    return { strref: Math.trunc(parseNumericExpr(nuiStrRef[0], "0")) };
  }
  const nuiVec = parseExprFunctionArgs(source, "NuiVec");
  if (nuiVec && nuiVec.length === 2) {
    return {
      x: parseNumericExpr(nuiVec[0], "0"),
      y: parseNumericExpr(nuiVec[1], "0"),
    };
  }
  const nuiRect = parseExprFunctionArgs(source, "NuiRect");
  if (nuiRect && nuiRect.length === 4) {
    return {
      x: parseNumericExpr(nuiRect[0], "0"),
      y: parseNumericExpr(nuiRect[1], "0"),
      w: parseNumericExpr(nuiRect[2], "0"),
      h: parseNumericExpr(nuiRect[3], "0"),
    };
  }
  const nuiColor = parseExprFunctionArgs(source, "NuiColor");
  if (nuiColor && nuiColor.length >= 3) {
    return {
      r: Math.trunc(parseNumericExpr(nuiColor[0], "255")),
      g: Math.trunc(parseNumericExpr(nuiColor[1], "255")),
      b: Math.trunc(parseNumericExpr(nuiColor[2], "255")),
      a: Math.trunc(parseNumericExpr(nuiColor[3], "255")),
    };
  }
  const nuiComboEntry = parseExprFunctionArgs(source, "NuiComboEntry");
  if (nuiComboEntry && nuiComboEntry.length === 2) {
    return [
      parseStringExpr(nuiComboEntry[0], '"Label"'),
      Math.trunc(parseNumericExpr(nuiComboEntry[1], "0")),
    ];
  }
  const nuiChartSlot = parseExprFunctionArgs(source, "NuiChartSlot");
  if (nuiChartSlot && nuiChartSlot.length === 4) {
    return {
      type: Math.trunc(parseNumericExpr(nuiChartSlot[0], "0")),
      legend: parseJuiExpr(nuiChartSlot[1], 'JsonString("Legend")'),
      color: parseJuiExpr(nuiChartSlot[2], "NuiColor(255, 255, 255, 255)"),
      data: parseJuiExpr(nuiChartSlot[3], "JsonArray()"),
    };
  }
  const nuiListTemplateCell = parseExprFunctionArgs(source, "NuiListTemplateCell");
  if (nuiListTemplateCell && nuiListTemplateCell.length === 3) {
    return [
      parseJuiExpr(nuiListTemplateCell[0], "JSON_NULL"),
      parseNumericExpr(nuiListTemplateCell[1], "0.0"),
      parseBoolExpr(nuiListTemplateCell[2], "TRUE"),
    ];
  }
  const nuiImageRegion = parseExprFunctionArgs(source, "NuiImageRegion");
  if (nuiImageRegion && nuiImageRegion.length === 2) {
    const base = parseJuiExpr(nuiImageRegion[0], "JSON_NULL");
    const out: JuiObject = isJuiObject(base) ? { ...base } : {};
    out.image_region = parseJuiExpr(nuiImageRegion[1], "JSON_NULL");
    return out;
  }
  const nuiDrawListImageRegion = parseExprFunctionArgs(source, "NuiDrawListImageRegion");
  if (nuiDrawListImageRegion && nuiDrawListImageRegion.length === 2) {
    const base = parseJuiExpr(nuiDrawListImageRegion[0], "JSON_NULL");
    const out: JuiObject = isJuiObject(base) ? { ...base } : {};
    out.image_region = parseJuiExpr(nuiDrawListImageRegion[1], "JSON_NULL");
    return out;
  }

  const numeric = parseNumericToken(source);
  if (numeric !== null) return numeric;
  return source;
}

function nuiElement(type: string, label: JuiValue, value: JuiValue): JuiObject {
  return {
    type,
    label,
    value,
  };
}

function toJuiObjectOrFallback(value: JuiValue, fallbackType = "spacer"): JuiObject {
  if (isJuiObject(value)) return { ...value };
  return nuiElement(fallbackType, null, null);
}

function serializeDrawListItemBase(
  typeToken: string,
  node: NuiNode,
  overrides?: Partial<JuiObject>,
): JuiObject {
  const base: JuiObject = {
    type: Math.trunc(parseNumericExpr(typeToken, "0")),
    enabled: parseJuiExpr(node.props.jEnabled, "JsonBool(TRUE)"),
    color: parseJuiExpr(node.props.jColor, "NuiColor(255, 255, 255, 255)"),
    fill: parseJuiExpr(node.props.jFill, "JsonBool(FALSE)"),
    line_thickness: parseJuiExpr(node.props.jLineThickness, "JsonFloat(1.0)"),
    order: Math.trunc(parseNumericExpr(node.props.nOrder, "NUI_DRAW_LIST_ITEM_ORDER_AFTER")),
    render: Math.trunc(parseNumericExpr(node.props.nRender, "NUI_DRAW_LIST_ITEM_RENDER_ALWAYS")),
    arrayBinds: parseBoolExpr(node.props.nBindArrays, "FALSE"),
  };
  if (overrides) {
    Object.assign(base, overrides);
  }
  return base;
}

function serializeNodeToJui(node: NuiNode): JuiValue {
  switch (node.componentName) {
    case "NuiId": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.id = parseStringExpr(node.props.sId, '"id"');
      return out;
    }
    case "NuiWidth": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.width = parseNumericExpr(node.props.fWidth, "0.0");
      return out;
    }
    case "NuiHeight": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.height = parseNumericExpr(node.props.fHeight, "0.0");
      return out;
    }
    case "NuiAspect": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.aspect = parseNumericExpr(node.props.fAspect, "0.0");
      return out;
    }
    case "NuiMargin": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.margin = parseNumericExpr(node.props.fMargin, "0.0");
      return out;
    }
    case "NuiPadding": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.padding = parseNumericExpr(node.props.fPadding, "0.0");
      return out;
    }
    case "NuiEnabled": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.enabled = parseJuiExpr(node.props.jEnabler, "JsonBool(TRUE)");
      return out;
    }
    case "NuiVisible": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.visible = parseJuiExpr(node.props.jVisible, "JsonBool(TRUE)");
      return out;
    }
    case "NuiTooltip": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.tooltip = parseJuiExpr(node.props.jTooltip, 'JsonString("")');
      return out;
    }
    case "NuiDisabledTooltip": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.disabled_tooltip = parseJuiExpr(node.props.jTooltip, 'JsonString("")');
      return out;
    }
    case "NuiEncouraged": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.encouraged = parseJuiExpr(node.props.jEncouraged, "JsonBool(TRUE)");
      return out;
    }
    case "NuiStyleForegroundColor": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.foreground_color = parseJuiExpr(node.props.jColor, "NuiColor(255, 255, 255, 255)");
      return out;
    }
    case "NuiStyleFont": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.font = parseJuiExpr(node.props.jFont, "JSON_STRING");
      return out;
    }
    case "NuiImageRegion":
    case "NuiDrawListImageRegion": {
      const child = node.children[0] ? serializeNodeToJui(node.children[0]) : null;
      const out = toJuiObjectOrFallback(child);
      out.image_region = parseJuiExpr(node.props.jRegion, "NuiRect(0.0, 0.0, 1.0, 1.0)");
      return out;
    }
    case "NuiWindow": {
      const rootChild = node.children[0] ? serializeNodeToJui(node.children[0]) : nuiElement("col", null, null);
      return {
        version: 1,
        title: parseJuiExpr(node.props.jTitle, 'JsonString("Window")'),
        root: toJuiObjectOrFallback(rootChild, "col"),
        geometry: parseJuiExpr(node.props.jGeometry, "NuiRect(-1.0, -1.0, 480.0, 320.0)"),
        resizable: parseJuiExpr(node.props.jResizable, "JsonBool(FALSE)"),
        collapsed: parseJuiExpr(node.props.jCollapsed, "JsonBool(FALSE)"),
        closable: parseJuiExpr(node.props.jClosable, "JsonBool(TRUE)"),
        transparent: parseJuiExpr(node.props.jTransparent, "JsonBool(FALSE)"),
        border: parseJuiExpr(node.props.jBorder, "JsonBool(TRUE)"),
        accepts_input: parseJuiExpr(node.props.jAcceptsInput, "JsonBool(TRUE)"),
        size_constraint: parseJuiExpr(node.props.jSizeConstraint, "JSON_NULL"),
        edge_constraint: parseJuiExpr(node.props.jEdgeConstraint, "JSON_NULL"),
        font: parseJuiExpr(node.props.jFont, "JSON_STRING"),
      };
    }
    case "NuiCol":
      return {
        ...nuiElement("col", null, null),
        children: node.children.map((child) => serializeNodeToJui(child)),
      };
    case "NuiRow":
      return {
        ...nuiElement("row", null, null),
        children: node.children.map((child) => serializeNodeToJui(child)),
      };
    case "NuiGroup": {
      let groupChild: JuiValue;
      if (!node.children.length) {
        groupChild = null;
      } else if (node.children.length === 1) {
        groupChild = serializeNodeToJui(node.children[0]);
      } else {
        groupChild = {
          ...nuiElement("col", null, null),
          children: node.children.map((child) => serializeNodeToJui(child)),
        };
      }
      return {
        ...nuiElement("group", null, null),
        children: [groupChild],
        border: parseBoolExpr(node.props.bBorder, "TRUE"),
        scrollbars: Math.trunc(parseNumericExpr(node.props.nScroll, "NUI_SCROLLBARS_AUTO")),
      };
    }
    case "NuiSpacer":
      return nuiElement("spacer", null, null);
    case "NuiLabel":
      return {
        ...nuiElement("label", null, parseJuiExpr(node.props.jValue, 'JsonString("Label")')),
        text_halign: parseJuiExpr(node.props.jHAlign, "JsonInt(NUI_HALIGN_LEFT)"),
        text_valign: parseJuiExpr(node.props.jVAlign, "JsonInt(NUI_VALIGN_MIDDLE)"),
      };
    case "NuiText":
      return {
        ...nuiElement("text", null, parseJuiExpr(node.props.jValue, 'JsonString("")')),
        border: parseBoolExpr(node.props.bBorder, "TRUE"),
        scrollbars: Math.trunc(parseNumericExpr(node.props.nScroll, "NUI_SCROLLBARS_AUTO")),
      };
    case "NuiButton":
      return nuiElement("button", parseJuiExpr(node.props.jLabel, 'JsonString("Label")'), null);
    case "NuiButtonImage":
      return nuiElement("button_image", parseJuiExpr(node.props.jResRef, 'JsonString("")'), null);
    case "NuiButtonSelect":
      return nuiElement("button_select", parseJuiExpr(node.props.jLabel, 'JsonString("Label")'), parseJuiExpr(node.props.jValue, "JsonBool(FALSE)"));
    case "NuiCheck":
      return nuiElement("check", parseJuiExpr(node.props.jLabel, 'JsonString("Label")'), parseJuiExpr(node.props.jBool, "JsonBool(FALSE)"));
    case "NuiImage":
      return {
        ...nuiElement("image", null, parseJuiExpr(node.props.jResRef, 'JsonString("")')),
        image_aspect: parseJuiExpr(node.props.jAspect, "JsonInt(NUI_ASPECT_FIT)"),
        image_halign: parseJuiExpr(node.props.jHAlign, "JsonInt(NUI_HALIGN_LEFT)"),
        image_valign: parseJuiExpr(node.props.jVAlign, "JsonInt(NUI_VALIGN_MIDDLE)"),
      };
    case "NuiCombo":
      return {
        ...nuiElement("combo", null, parseJuiExpr(node.props.jSelected, "JsonInt(0)")),
        elements: parseJuiExpr(node.props.jElements, "JsonArray()"),
      };
    case "NuiSliderFloat":
      return {
        ...nuiElement("sliderf", null, parseJuiExpr(node.props.jValue, "JsonFloat(0.5)")),
        min: parseJuiExpr(node.props.jMin, "JsonFloat(0.0)"),
        max: parseJuiExpr(node.props.jMax, "JsonFloat(1.0)"),
        step: parseJuiExpr(node.props.jStepSize, "JsonFloat(0.01)"),
      };
    case "NuiSlider":
      return {
        ...nuiElement("slider", null, parseJuiExpr(node.props.jValue, "JsonInt(0)")),
        min: parseJuiExpr(node.props.jMin, "JsonInt(0)"),
        max: parseJuiExpr(node.props.jMax, "JsonInt(100)"),
        step: parseJuiExpr(node.props.jStepSize, "JsonInt(1)"),
      };
    case "NuiProgress":
      return nuiElement("progress", null, parseJuiExpr(node.props.jValue, "JsonFloat(1.0)"));
    case "NuiTextEdit":
      return {
        ...nuiElement("textedit", parseJuiExpr(node.props.jPlaceholder, 'JsonString("")'), parseJuiExpr(node.props.jValue, 'JsonString("")')),
        max: Math.trunc(parseNumericExpr(node.props.nMaxLength, "64")),
        multiline: parseBoolExpr(node.props.bMultiline, "FALSE"),
        wordwrap: parseBoolExpr(node.props.bWordWrap, "TRUE"),
      };
    case "NuiList": {
      const templateFromChildren = node.children.length
        ? node.children.map((child) => serializeNodeToJui(child))
        : parseJuiExpr(node.props.jTemplate, "JsonArray()");
      return {
        ...nuiElement("list", null, null),
        row_template: templateFromChildren,
        row_count: parseJuiExpr(node.props.jRowCount, "JsonInt(0)"),
        row_height: parseNumericExpr(node.props.fRowHeight, "NUI_STYLE_ROW_HEIGHT"),
        border: parseBoolExpr(node.props.bBorder, "TRUE"),
        scrollbars: Math.trunc(parseNumericExpr(node.props.nScroll, "NUI_SCROLLBARS_Y")),
      };
    }
    case "NuiListTemplateCell": {
      const elem = node.children[0] ? serializeNodeToJui(node.children[0]) : parseJuiExpr(node.props.jElem, "JSON_NULL");
      return [
        elem,
        parseNumericExpr(node.props.fWidth, "0.0"),
        parseBoolExpr(node.props.bVariable, "TRUE"),
      ];
    }
    case "NuiColorPicker":
      return nuiElement("color_picker", null, parseJuiExpr(node.props.jColor, "NuiColor(255, 255, 255, 255)"));
    case "NuiOptions":
      return {
        ...nuiElement("options", null, parseJuiExpr(node.props.jValue, "JsonInt(-1)")),
        direction: Math.trunc(parseNumericExpr(node.props.nDirection, "NUI_DIRECTION_HORIZONTAL")),
        elements: parseJuiExpr(node.props.jElements, "JsonArray()"),
      };
    case "NuiToggles":
      return {
        ...nuiElement("tabbar", null, parseJuiExpr(node.props.jValue, "JsonInt(-1)")),
        direction: Math.trunc(parseNumericExpr(node.props.nDirection, "NUI_DIRECTION_HORIZONTAL")),
        elements: parseJuiExpr(node.props.jElements, "JsonArray()"),
      };
    case "NuiChart":
      return nuiElement("chart", null, parseJuiExpr(node.props.jSlots, "JsonArray()"));
    case "NuiDrawListPolyLine":
      return {
        ...serializeDrawListItemBase("NUI_DRAW_LIST_ITEM_TYPE_POLYLINE", node),
        points: parseJuiExpr(node.props.jPoints, "JsonArray()"),
      };
    case "NuiDrawListCurve":
      return {
        ...serializeDrawListItemBase("NUI_DRAW_LIST_ITEM_TYPE_CURVE", node, {
          fill: false,
        }),
        a: parseJuiExpr(node.props.jA, "NuiVec(0.0, 0.0)"),
        b: parseJuiExpr(node.props.jB, "NuiVec(100.0, 100.0)"),
        ctrl0: parseJuiExpr(node.props.jCtrl0, "NuiVec(25.0, 0.0)"),
        ctrl1: parseJuiExpr(node.props.jCtrl1, "NuiVec(75.0, 100.0)"),
      };
    case "NuiDrawListCircle":
      return {
        ...serializeDrawListItemBase("NUI_DRAW_LIST_ITEM_TYPE_CIRCLE", node),
        rect: parseJuiExpr(node.props.jRect, "NuiRect(0.0, 0.0, 120.0, 24.0)"),
      };
    case "NuiDrawListArc":
      return {
        ...serializeDrawListItemBase("NUI_DRAW_LIST_ITEM_TYPE_ARC", node),
        c: parseJuiExpr(node.props.jCenter, "NuiVec(0.0, 0.0)"),
        radius: parseJuiExpr(node.props.jRadius, "JsonFloat(32.0)"),
        amin: parseJuiExpr(node.props.jAMin, "JsonFloat(0.0)"),
        amax: parseJuiExpr(node.props.jAMax, "JsonFloat(6.283185307179586)"),
      };
    case "NuiDrawListText":
      return {
        ...serializeDrawListItemBase("NUI_DRAW_LIST_ITEM_TYPE_TEXT", node, {
          fill: null,
          line_thickness: null,
        }),
        rect: parseJuiExpr(node.props.jRect, "NuiRect(0.0, 0.0, 120.0, 24.0)"),
        text: parseJuiExpr(node.props.jText, 'JsonString("")'),
        font: parseJuiExpr(node.props.jFont, "JSON_STRING"),
      };
    case "NuiDrawListImage":
      return {
        ...serializeDrawListItemBase("NUI_DRAW_LIST_ITEM_TYPE_IMAGE", node, {
          color: null,
          fill: null,
          line_thickness: null,
        }),
        image: parseJuiExpr(node.props.jResRef, 'JsonString("")'),
        rect: parseJuiExpr(node.props.jPos, "NuiRect(0.0, 0.0, 120.0, 24.0)"),
        image_aspect: parseJuiExpr(node.props.jAspect, "JsonInt(NUI_ASPECT_FIT)"),
        image_halign: parseJuiExpr(node.props.jHAlign, "JsonInt(NUI_HALIGN_LEFT)"),
        image_valign: parseJuiExpr(node.props.jVAlign, "JsonInt(NUI_VALIGN_MIDDLE)"),
      };
    case "NuiDrawListLine":
      return {
        ...serializeDrawListItemBase("NUI_DRAW_LIST_ITEM_TYPE_LINE", node, {
          fill: null,
        }),
        a: parseJuiExpr(node.props.jA, "NuiVec(0.0, 0.0)"),
        b: parseJuiExpr(node.props.jB, "NuiVec(100.0, 100.0)"),
      };
    case "NuiDrawListRect":
      return {
        ...serializeDrawListItemBase("NUI_DRAW_LIST_ITEM_TYPE_RECT", node),
        rect: parseJuiExpr(node.props.jRect, "NuiRect(0.0, 0.0, 120.0, 24.0)"),
      };
    case "NuiDrawList": {
      const hostRaw = node.children[0] ? serializeNodeToJui(node.children[0]) : nuiElement("spacer", null, null);
      const host = toJuiObjectOrFallback(hostRaw);
      host.draw_list = node.children.slice(1).map((child) => serializeNodeToJui(child));
      host.draw_list_scissor = parseJuiExpr(node.props.jScissor, "NuiRect(0.0, 0.0, 512.0, 512.0)");
      return host;
    }
    default:
      return {
        ...nuiElement(node.componentName.replace(/^Nui/, "").toLowerCase(), null, null),
        children: node.children.map((child) => serializeNodeToJui(child)),
      };
  }
}

function buildJuiWindowPayload(root: NuiNode[]): JuiObject {
  const firstWindow = root.find((node) => node.componentName === "NuiWindow");
  if (firstWindow) {
    const payload = serializeNodeToJui(firstWindow);
    if (isJuiObject(payload)) return payload;
  }

  const fallbackRootNode = root[0] ? serializeNodeToJui(root[0]) : nuiElement("col", null, null);
  return {
    version: 1,
    title: "Window",
    root: toJuiObjectOrFallback(fallbackRootNode, "col"),
    geometry: { x: -1.0, y: -1.0, w: 480.0, h: 320.0 },
    resizable: false,
    collapsed: false,
    closable: true,
    transparent: false,
    border: true,
    accepts_input: true,
    size_constraint: null,
    edge_constraint: null,
    font: "",
  };
}

export interface NuiResRefArtifacts {
  usageNotes: string;
  juiResRef: string;
  juiContent: string;
  loaderScriptResRef: string;
  loaderScript: string;
  eventScriptResRef: string;
  eventScript: string;
}

export function generateNuiResRefArtifacts(
  project: NuiProjectMeta,
  root: NuiNode[],
  componentMap?: Map<string, NuiComponent>,
): NuiResRefArtifacts {
  const projectName = project.name.trim() || "nui_project";
  const windowId = project.windowId.trim() || "NUI_WINDOW";
  const eventScript = project.eventScript.trim() || "nui_window_ev";
  const juiResRef = toResRef(`nb_${projectName}`, "nb_nui_window");
  const loaderScriptResRef = toResRefWithSuffix(juiResRef, "open", "nb_nui");
  const openFunctionName = toNwScriptIdentifier(`NUIOpen_${projectName}`, "NUIOpenProject");
  const mainWindowCount = root.filter((node) => node.componentName === "NuiWindow").length;
  const windowCountNote =
    mainWindowCount === 1
      ? "// Layout currently has 1 NuiWindow."
      : `// Layout currently has ${mainWindowCount} NuiWindow nodes. This resref workflow expects a single top-level window.`;

  const usage = [
    "// NUI RESREF LOADER PACK (NuiCreateFromResRef)",
    "//",
    `// 1) Build and ship a client-visible file: ${juiResRef}.jui`,
    "//    Put it in hak/override/nwsync so the client can resolve this resref.",
    `// 2) Compile and run ${loaderScriptResRef}.nss to open that .jui at runtime.`,
    `// 3) Compile ${eventScript}.nss as your NUI event handler (or pass different override in loader).`,
    `// 4) Window ID: ${windowId}`,
    `// 5) Event script override passed by loader: ${eventScript}`,
    windowCountNote,
  ].join("\n");

  const juiPayload = buildJuiWindowPayload(root);
  const juiContent = JSON.stringify(juiPayload, null, 2);

  const loaderScript = [
    '#include "nw_inc_nui"',
    "",
    `const string NUI_RESREF = "${juiResRef}";`,
    `const string NUI_WINDOW_ID = "${windowId}";`,
    `const string NUI_EVENT_SCRIPT = "${eventScript}";`,
    "",
    `void ${openFunctionName}(object oPC)`,
    "{",
    "    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC) || GetIsDM(oPC)) return;",
    "",
    "    int nOldToken = NuiFindWindow(oPC, NUI_WINDOW_ID);",
    "    if (nOldToken != 0)",
    "    {",
    "        NuiDestroy(oPC, nOldToken);",
    "    }",
    "",
    "    int nToken = NuiCreateFromResRef(oPC, NUI_RESREF, NUI_WINDOW_ID, NUI_EVENT_SCRIPT);",
    "    if (nToken == 0)",
    "    {",
    '        SendMessageToPC(oPC, "NUI open failed: missing " + NUI_RESREF + ".jui on client.");',
    "    }",
    "}",
    "",
    "void main()",
    "{",
    "    if (GetIsObjectValid(OBJECT_SELF) && GetIsPC(OBJECT_SELF))",
    "    {",
    `        ${openFunctionName}(OBJECT_SELF);`,
    "        return;",
    "    }",
    "",
    "    object oPC = GetFirstPC();",
    "    while (GetIsObjectValid(oPC))",
    "    {",
    `        ${openFunctionName}(oPC);`,
    "        oPC = GetNextPC();",
    "    }",
    "}",
  ].join("\n");

  const swapGroupIds: string[] = [];
  root.forEach((node) => collectSwapGroupIds(node, swapGroupIds));
  const uniqueSwapGroupIds = [...new Set(swapGroupIds)];
  const swapRouteSpecs = collectSwapRouteSpecs(root);
  const swapMainId = swapRouteSpecs[0]?.swapId ?? uniqueSwapGroupIds[0] ?? "swap_main";
  const swapFunctionLines = componentMap ? buildSwapLayoutFunctionLines(swapRouteSpecs, componentMap) : [];
  const bindUsages = collectBindUsagesMap(root);
  const encouragedRouteSpecs = collectEncouragedRouteSpecs(root);
  const encouragedOpenInitLines = buildEncouragedOpenInitLines(encouragedRouteSpecs, "        ");
  const listTemplatePreviewInitExpressions = collectListTemplatePreviewInitExpressions(root);
  const openBindInitLines = buildBindInitOpenBlockLines(
    bindUsages,
    "sEvent",
    "    ",
    encouragedOpenInitLines,
    listTemplatePreviewInitExpressions,
  );
  const encouragedRouteHandlerLines = buildEncouragedClickRouteLines(encouragedRouteSpecs, "sElement", "nIndex", "    ");
  const requiresLibNui = encouragedRouteSpecs.length > 0;

  const swapRouteSummary = swapRouteSpecs.length
    ? [
        "// Auto-generated swap routes from NuiSwapLayout:",
        ...swapRouteSpecs.map((spec) => `// - click "${spec.triggerId}" => ${spec.functionName}() => slot "${spec.swapId}"`),
      ]
    : ["// No auto swap routes detected from NuiSwapLayout."];
  const hasSwapFunctions = swapFunctionLines.length > 0;
  const swapRouteHandlerLines = hasSwapFunctions
    ? swapRouteSpecs.flatMap((spec) => [
        `    if (sEvent == "click" && sElement == "${escapeNwString(spec.triggerId)}")`,
        "    {",
        `        NuiSetGroupLayout(oPC, nToken, "${escapeNwString(spec.swapId)}", ${spec.functionName}());`,
        "        return;",
        "    }",
      ])
    : swapRouteSpecs.length
      ? [
          "    // Swap routes detected, but this export path has no function body generator available.",
          ...swapRouteSpecs.map(
            (spec) =>
              `    // TODO: if (sEvent == "click" && sElement == "${escapeNwString(spec.triggerId)}") NuiSetGroupLayout(oPC, nToken, "${escapeNwString(spec.swapId)}", /* your json layout */);`,
          ),
        ]
      : [];

  const eventScriptTemplate = [
    ...(requiresLibNui ? ['#include "lib_nui"'] : ['#include "nw_inc_nui"']),
    "",
    'const string NUI_SWAP_ROOT = "_window_";',
    `const string NUI_SWAP_MAIN = "${escapeNwString(swapMainId)}";`,
    ...(uniqueSwapGroupIds.length
      ? [
          "// Swap-ready NuiGroup ids detected:",
          ...uniqueSwapGroupIds.map((id) => `// - ${id}`),
        ]
      : ['// No NuiId(NuiGroup(...)) swap anchor detected; set NUI_SWAP_MAIN manually.']),
    ...swapRouteSummary,
    "",
    ...swapFunctionLines,
    "",
    "void main()",
    "{",
    "    object oPC = NuiGetEventPlayer();",
    "    int nToken = NuiGetEventWindow();",
    "    string sEvent = NuiGetEventType();",
    "    string sElement = NuiGetEventElement();",
    "    int nIndex = NuiGetEventArrayIndex();",
    "    json jPayload = NuiGetEventPayload();",
    "    string sWindowId = NuiGetWindowId(oPC, nToken);",
    "",
    `    if (sWindowId != "${windowId}") return;`,
    "",
    ...(openBindInitLines.length
      ? openBindInitLines
      : [
          '    if (sEvent == "open")',
          "    {",
          "        // TODO: one-time window init (SetLocal*, feed binds, watches).",
          '        // Example: NuiSetBindWatch(oPC, nToken, "view_mode", TRUE);',
          "        return;",
          "    }",
          "",
        ]),
    '    if (sEvent == "close")',
    "    {",
    "        // TODO: cleanup locals/userdata if needed.",
    "        return;",
    "    }",
    "",
    '    if (sEvent == "watch")',
    "    {",
    "        // For watch events, sElement is bind name.",
    "        json jValue = NuiGetBind(oPC, nToken, sElement);",
    '        // WARNING: writing the same watched bind in this block can recurse.',
    "        // Guard any writeback path with local lock and strict conditions.",
    "        // Example pattern:",
    '        // if (sElement == "view_mode")',
    "        // {",
    '        //     if (GetLocalInt(oPC, "NUI_WATCH_LOCK") == TRUE) return;',
    '        //     SetLocalInt(oPC, "NUI_WATCH_LOCK", TRUE);',
    '        //     // NuiSetBind(oPC, nToken, "some_other_bind", JsonInt(1));',
    '        //     DeleteLocalInt(oPC, "NUI_WATCH_LOCK");',
    "        // }",
    "        return;",
    "    }",
    "",
    ...swapRouteHandlerLines,
    ...(swapRouteHandlerLines.length ? [""] : []),
    ...encouragedRouteHandlerLines,
    ...(encouragedRouteHandlerLines.length ? [""] : []),
    "",
    '    if (sEvent != "click" && sEvent != "mousedown" && sEvent != "mouseup" && sEvent != "mousescroll") return;',
    "",
    '    if (sElement == "btn_ok")',
    "    {",
    "        // TODO: handle button / draw-host click.",
    "        return;",
    "    }",
    "",
    "    // debug hook (optional):",
    "    // SendMessageToPC(oPC, sEvent + \" | \" + sElement + \" | idx=\" + IntToString(nIndex));",
    "    // SendMessageToPC(oPC, \"payload=\" + JsonDump(jPayload));",
    "}",
  ].join("\n");

  return {
    usageNotes: usage,
    juiResRef,
    juiContent,
    loaderScriptResRef,
    loaderScript,
    eventScriptResRef: eventScript,
    eventScript: eventScriptTemplate,
  };
}

export function generateNuiResRefPack(
  project: NuiProjectMeta,
  root: NuiNode[],
  componentMap?: Map<string, NuiComponent>,
): string {
  const artifacts = generateNuiResRefArtifacts(project, root, componentMap);
  return [
    artifacts.usageNotes,
    "",
    `// ===== FILE: ${artifacts.juiResRef}.jui =====`,
    artifacts.juiContent,
    "",
    `// ===== FILE: ${artifacts.loaderScriptResRef}.nss =====`,
    artifacts.loaderScript,
    "",
    `// ===== FILE: ${artifacts.eventScriptResRef}.nss =====`,
    artifacts.eventScript,
  ].join("\n");
}

export interface NuiScriptOutputArtifacts {
  juiResRef: string;
  juiContent: string;
  projectScriptResRef: string;
  projectScript: string;
  eventScriptResRef: string;
  eventScript: string;
  mergeScripts: boolean;
  includeCustomLib: boolean;
  customLibScriptResRef: string;
  customLibScript: string;
}

interface SplitNwScriptOutput {
  projectScript: string;
  eventScript: string;
}

function generateCustomLibNuiScript(): string {
  return [
    '#include "nw_inc_nui"',
    "",
    "// Shared helpers for custom builder components.",
    "// Curated from analyzed module variants (Duel/Mailbox/LFG style).",
    "",
    "const string NUILIB_EVENT_OPEN        = \"open\";",
    "const string NUILIB_EVENT_CLOSE       = \"close\";",
    "const string NUILIB_EVENT_CLICK       = \"click\";",
    "const string NUILIB_EVENT_WATCH       = \"watch\";",
    "const string NUILIB_EVENT_MOUSEDOWN   = \"mousedown\";",
    "const string NUILIB_EVENT_MOUSEUP     = \"mouseup\";",
    "const string NUILIB_EVENT_MOUSESCROLL = \"mousescroll\";",
    "",
    "const string NUILIB_DATA_ENCOURAGED = \"NUI_DATA_ENCOURAGED\";",
    "const string NUILIB_DATA_ROW        = \"NUI_DATA_ROW\";",
    "",
    "int NuiLib_IsExpectedWindow(object oPC, int nToken, string sWindowId)",
    "{",
    "    if (!GetIsObjectValid(oPC) || nToken == 0) return FALSE;",
    '    if (sWindowId == "") return FALSE;',
    "    return NuiGetWindowId(oPC, nToken) == sWindowId;",
    "}",
    "",
    "int NuiLib_FindWindowToken(object oPC, string sWindowId)",
    "{",
    "    if (!GetIsObjectValid(oPC)) return 0;",
    '    if (sWindowId == \"\") return 0;',
    "    return NuiFindWindow(oPC, sWindowId);",
    "}",
    "",
    "void NuiLib_DestroyWindowIfOpen(object oPC, string sWindowId)",
    "{",
    "    if (!GetIsObjectValid(oPC)) return;",
    "    int nToken = NuiLib_FindWindowToken(oPC, sWindowId);",
    "    if (nToken != 0) NuiDestroy(oPC, nToken);",
    "}",
    "",
    "void NuiLib_SetSwapLayoutSafe(object oPC, int nToken, string sSwapId, json jLayout)",
    "{",
    "    if (!GetIsObjectValid(oPC) || nToken == 0) return;",
    '    if (sSwapId == "") return;',
    "    NuiSetGroupLayout(oPC, nToken, sSwapId, jLayout);",
    "}",
    "",
    "void NuiLib_SetBindSafe(object oPC, int nToken, string sBind, json jValue)",
    "{",
    "    if (!GetIsObjectValid(oPC) || nToken == 0) return;",
    '    if (sBind == "") return;',
    "    NuiSetBind(oPC, nToken, sBind, jValue);",
    "}",
    "",
    "json NuiLib_GetBindOrDefault(object oPC, int nToken, string sBind, json jFallback)",
    "{",
    "    if (!GetIsObjectValid(oPC) || nToken == 0) return jFallback;",
    '    if (sBind == \"\") return jFallback;',
    "    json jValue = NuiGetBind(oPC, nToken, sBind);",
    "    if (JsonGetType(jValue) == JSON_TYPE_NULL) return jFallback;",
    "    return jValue;",
    "}",
    "",
    "float NuiLib_GetScaleDimension(object oPC, float fDimension, float fScaleMax = 1.5)",
    "{",
    "    if (!GetIsObjectValid(oPC)) return fDimension;",
    "    int nScaleGui = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_SCALE);",
    "    float fScaleGui = IntToFloat(nScaleGui) / 100.0;",
    "    if (fScaleGui <= 0.0) fScaleGui = 1.0;",
    "    if (fScaleGui > fScaleMax) fScaleGui = fScaleMax;",
    "    return fDimension / fScaleGui;",
    "}",
    "",
    "json NuiLib_CreateEmptyRow(object oPC, float fHeight, float fScaleMax = 1.5)",
    "{",
    "    json jRow = JsonArray();",
    "    if (fHeight <= 0.0)",
    "    {",
    "        jRow = JsonArrayInsert(jRow, NuiSpacer());",
    "    }",
    "    else",
    "    {",
    "        jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), NuiLib_GetScaleDimension(oPC, fHeight, fScaleMax)));",
    "    }",
    "    return NuiRow(jRow);",
    "}",
    "",
    "json NuiLib_GetNwnGoldColor()",
    "{",
    "    return NuiColor(185, 150, 100, 255);",
    "}",
    "",
    "void NuiLib_EncouragedOff(object oPC, int nToken, string sBindEncouraged = NUILIB_DATA_ENCOURAGED, string sBindRow = NUILIB_DATA_ROW)",
    "{",
    "    if (!GetIsObjectValid(oPC) || nToken == 0) return;",
    "    json jRow = NuiGetBind(oPC, nToken, sBindRow);",
    "    if (JsonGetType(jRow) == JSON_TYPE_NULL) return;",
    "    int nRow = JsonGetInt(jRow);",
    "    if (nRow < 0) return;",
    "    json jEnc = NuiGetBind(oPC, nToken, sBindEncouraged);",
    "    if (JsonGetType(jEnc) != JSON_TYPE_ARRAY) return;",
    "    jEnc = JsonArraySet(jEnc, nRow, JsonBool(FALSE));",
    "    NuiSetBind(oPC, nToken, sBindEncouraged, jEnc);",
    "    NuiSetBind(oPC, nToken, sBindRow, JsonNull());",
    "}",
    "",
    "void NuiLib_EncouragedOn(object oPC, int nToken, int nRow, string sBindEncouraged = NUILIB_DATA_ENCOURAGED, string sBindRow = NUILIB_DATA_ROW)",
    "{",
    "    if (!GetIsObjectValid(oPC) || nToken == 0) return;",
    "    if (nRow < 0) return;",
    "    json jEnc = NuiGetBind(oPC, nToken, sBindEncouraged);",
    "    if (JsonGetType(jEnc) != JSON_TYPE_ARRAY)",
    "    {",
    "        jEnc = JsonArray();",
    "    }",
    "    int nLen = JsonGetLength(jEnc);",
    "    int i;",
    "    for (i = nLen; i <= nRow; i++)",
    "    {",
    "        jEnc = JsonArrayInsert(jEnc, JsonBool(FALSE));",
    "    }",
    "    jEnc = JsonArraySet(jEnc, nRow, JsonBool(TRUE));",
    "    NuiSetBind(oPC, nToken, sBindEncouraged, jEnc);",
    "    NuiSetBind(oPC, nToken, sBindRow, JsonInt(nRow));",
    "}",
    "",
    "void NuiLib_EncouragedToggleRow(object oPC, int nToken, int nRow, int nRowCount = 0, string sBindEncouraged = NUILIB_DATA_ENCOURAGED, string sBindRow = NUILIB_DATA_ROW)",
    "{",
    "    if (!GetIsObjectValid(oPC) || nToken == 0) return;",
    "    if (nRow < 0) return;",
    "    if (nRowCount < (nRow + 1)) nRowCount = nRow + 1;",
    "",
    "    json jEnc = NuiGetBind(oPC, nToken, sBindEncouraged);",
    "    if (JsonGetType(jEnc) != JSON_TYPE_ARRAY)",
    "    {",
    "        jEnc = JsonArray();",
    "    }",
    "",
    "    int nLen = JsonGetLength(jEnc);",
    "    int i;",
    "    for (i = nLen; i < nRowCount; i++)",
    "    {",
    "        jEnc = JsonArrayInsert(jEnc, JsonBool(FALSE));",
    "    }",
    "",
    "    int bWasEnabled = JsonGetInt(JsonArrayGet(jEnc, nRow));",
    "    if (bWasEnabled)",
    "    {",
    "        jEnc = JsonArraySet(jEnc, nRow, JsonBool(FALSE));",
    "        NuiSetBind(oPC, nToken, sBindEncouraged, jEnc);",
    "        NuiSetBind(oPC, nToken, sBindRow, JsonNull());",
    "        return;",
    "    }",
    "",
    "    nLen = JsonGetLength(jEnc);",
    "    for (i = 0; i < nLen; i++)",
    "    {",
    "        jEnc = JsonArraySet(jEnc, i, JsonBool(FALSE));",
    "    }",
    "    jEnc = JsonArraySet(jEnc, nRow, JsonBool(TRUE));",
    "    NuiSetBind(oPC, nToken, sBindEncouraged, jEnc);",
    "    NuiSetBind(oPC, nToken, sBindRow, JsonInt(nRow));",
    "}",
    "",
    "void NuiLib_CycleComboIndex(object oPC, int nToken, string sBindSelected, int nMax, int nDelta)",
    "{",
    "    if (!GetIsObjectValid(oPC) || nToken == 0) return;",
    '    if (sBindSelected == \"\") return;',
    "    if (nMax <= 0) return;",
    "    int nCurrent = JsonGetInt(NuiGetBind(oPC, nToken, sBindSelected));",
    "    nCurrent += nDelta;",
    "    if (nCurrent < 0) nCurrent = nMax - 1;",
    "    if (nCurrent >= nMax) nCurrent = 0;",
    "    NuiSetBind(oPC, nToken, sBindSelected, JsonInt(nCurrent));",
    "}",
    "",
    "string NuiLib_IntToPaddedString(int nValue, int nLength = 4, int nSigned = FALSE)",
    "{",
    "    string sValue = IntToString(nValue);",
    "    if (nSigned && nValue >= 0) sValue = \"+\" + sValue;",
    "    while (GetStringLength(sValue) < nLength)",
    "    {",
    "        sValue = \"0\" + sValue;",
    "    }",
    "    return sValue;",
    "}",
  ].join("\n");
}

function splitGeneratedNwScript(generated: string, eventScriptResRef: string): SplitNwScriptOutput {
  const lines = generated.split("\n");
  const includeLines = lines.filter((line) => line.startsWith('#include "'));
  const hasCustomLibInclude = includeLines.includes('#include "lib_nui"');
  const projectHeaderLines = ['#include "nw_inc_nui"', ""];
  // lib_nui already includes nw_inc_nui, so we keep a single include in event script.
  const eventHeaderLines = hasCustomLibInclude ? ['#include "lib_nui"', ""] : ['#include "nw_inc_nui"', ""];
  const buildStartIndex = lines.findIndex((line) => line.startsWith("void Build_"));
  const swapHelpersIndex = lines.findIndex((line) => line.startsWith("// Swap target helpers for NuiSetGroupLayout:"));
  const eventStartIndex = lines.findIndex((line) => line.startsWith(`void ${eventScriptResRef}()`));
  const swapFunctionsHeaderIndex = lines.findIndex((line) => line.startsWith("// Auto-generated NuiSwapLayout view functions:"));
  const sectionFunctionsHeaderIndex = lines.findIndex((line) =>
    line.startsWith("// Auto-generated layout section functions (readability helpers):"),
  );

  if (buildStartIndex < 0 || eventStartIndex < 0) {
    return { projectScript: generated.trim(), eventScript: generated.trim() };
  }

  const buildEndIndexExclusive = swapHelpersIndex > buildStartIndex ? swapHelpersIndex : eventStartIndex;
  const projectScriptLines: string[] = [...projectHeaderLines];
  if (sectionFunctionsHeaderIndex >= 0 && sectionFunctionsHeaderIndex < buildStartIndex) {
    projectScriptLines.push(...lines.slice(sectionFunctionsHeaderIndex, buildStartIndex), "");
  }
  projectScriptLines.push(...lines.slice(buildStartIndex, buildEndIndexExclusive));

  const eventScriptLines: string[] = [...eventHeaderLines];
  if (swapFunctionsHeaderIndex >= 0 && swapFunctionsHeaderIndex < buildStartIndex) {
    const swapBlockEnd =
      sectionFunctionsHeaderIndex > swapFunctionsHeaderIndex && sectionFunctionsHeaderIndex < buildStartIndex
        ? sectionFunctionsHeaderIndex
        : buildStartIndex;
    eventScriptLines.push(...lines.slice(swapFunctionsHeaderIndex, swapBlockEnd), "");
  }
  const eventBlockStart = swapHelpersIndex >= 0 ? swapHelpersIndex : eventStartIndex;
  eventScriptLines.push(...lines.slice(eventBlockStart));

  return {
    projectScript: projectScriptLines.join("\n").trim(),
    eventScript: eventScriptLines.join("\n").trim(),
  };
}

export function generateNuiScriptOutputArtifacts(
  project: NuiProjectMeta,
  root: NuiNode[],
  componentMap: Map<string, NuiComponent>,
  options: { mergeScripts?: boolean } = {},
): NuiScriptOutputArtifacts {
  const projectScriptResRef = toResRef(project.name.trim(), "nui_project");
  const eventScriptResRef = toResRef(project.eventScript.trim(), "nui_window_ev");
  const customLibScriptResRef = "lib_nui";
  const mergeScripts = options.mergeScripts === true || project.mergeScripts === true;

  const normalizedProject: NuiProjectMeta = {
    ...project,
    name: projectScriptResRef,
    eventScript: eventScriptResRef,
  };

  const resRefArtifacts = generateNuiResRefArtifacts(normalizedProject, root, componentMap);
  const generated = generateNwScript(normalizedProject, root, componentMap);
  const split = splitGeneratedNwScript(generated, eventScriptResRef);
  const projectScript = mergeScripts ? generated.trim() : split.projectScript;
  const eventScript = mergeScripts ? "" : split.eventScript;
  const includeCustomLib = /#include\s+"lib_nui"/.test(projectScript) || /#include\s+"lib_nui"/.test(eventScript);

  return {
    juiResRef: resRefArtifacts.juiResRef,
    juiContent: resRefArtifacts.juiContent,
    projectScriptResRef,
    projectScript,
    eventScriptResRef,
    eventScript,
    mergeScripts,
    includeCustomLib,
    customLibScriptResRef,
    customLibScript: generateCustomLibNuiScript(),
  };
}

export function generateNwScript(project: NuiProjectMeta, root: NuiNode[], componentMap: Map<string, NuiComponent>): string {
  if (!root.length) {
    return "// Empty project. Add at least one NuiWindow.";
  }

  const baseWindowId = project.windowId.trim() || "NUI_WINDOW";
  const windowIds = buildWindowIds(baseWindowId, root);
  const swapRouteSpecs = collectSwapRouteSpecs(root);
  const swapFunctionLines = buildSwapLayoutFunctionLines(swapRouteSpecs, componentMap);
  const swapTriggerIdSet = new Set(swapRouteSpecs.map((spec) => spec.triggerId));
  const encouragedRouteSpecs = collectEncouragedRouteSpecs(root);
  const requiresLibNui = encouragedRouteSpecs.length > 0;

  const lines: string[] = [];
  if (requiresLibNui) {
    lines.push('#include "lib_nui"');
  } else {
    lines.push('#include "nw_inc_nui"');
  }
  lines.push("");
  if (swapFunctionLines.length) {
    lines.push("// Auto-generated NuiSwapLayout view functions:");
    swapRouteSpecs.forEach((spec) => {
      lines.push(`// - click "${spec.triggerId}" swaps slot "${spec.swapId}"`);
    });
    lines.push("");
    lines.push(...swapFunctionLines);
  }
  const sectionFunctionLines: string[] = [];
  const ctx: NodeCodeGenContext = {
    counter: 1,
    sectionFunctions: {
      enabled: true,
      functionLines: sectionFunctionLines,
      functionNameByNodeId: new Map<string, string>(),
      usedFunctionNames: new Set<string>(),
      counter: 1,
    },
  };

  const buildLines: string[] = [];
  buildLines.push(`void Build_${project.name.trim()}(object oPC)`);
  buildLines.push("{");
  let windowCursor = 0;

  for (const topNode of root) {
    const nodeLines: string[] = [];
    const topVar = generateNodeCode(topNode, componentMap, nodeLines, ctx);
    nodeLines.forEach((line) => buildLines.push(`    ${line}`));

    if (topNode.componentName === "NuiWindow") {
      const winId = windowIds[windowCursor] ?? baseWindowId;
      windowCursor += 1;
      buildLines.push(`    int nToken${windowCursor} = NuiCreate(oPC, ${topVar}, "${winId}", "${project.eventScript.trim()}");`);
      buildLines.push(`    // nToken${windowCursor} ready`);
    } else {
      buildLines.push(`    // Top node ${topNode.componentName} generated as ${topVar}`);
    }
    buildLines.push("");
  }

  buildLines.push("}");
  buildLines.push("");
  if (sectionFunctionLines.length) {
    lines.push("// Auto-generated layout section functions (readability helpers):");
    lines.push(...sectionFunctionLines);
  }
  lines.push(...buildLines);

  const allIds: string[] = [];
  root.forEach((node) => collectNuiIds(node, allIds));
  const uniqueIds = [...new Set(allIds)];
  const bindUsages = collectBindUsagesMap(root);
  const encouragedOpenInitLines = buildEncouragedOpenInitLines(encouragedRouteSpecs, "            ");
  const listTemplatePreviewInitExpressions = collectListTemplatePreviewInitExpressions(root);
  const openBindInitLines = buildBindInitOpenBlockLines(
    bindUsages,
    "sEventType",
    "        ",
    encouragedOpenInitLines,
    listTemplatePreviewInitExpressions,
  );
  const encouragedRoutesById = new Map<string, EncouragedRouteSpec[]>();
  encouragedRouteSpecs.forEach((spec) => {
    const bucket = encouragedRoutesById.get(spec.nuiId) ?? [];
    bucket.push(spec);
    encouragedRoutesById.set(spec.nuiId, bucket);
  });
  const routedNuiIds = uniqueIds.filter((id) => !swapTriggerIdSet.has(id));
  const swapGroupIds: string[] = [];
  root.forEach((node) => collectSwapGroupIds(node, swapGroupIds));
  const uniqueSwapGroupIds = [...new Set(swapGroupIds)];
  const swapMainId = swapRouteSpecs[0]?.swapId ?? uniqueSwapGroupIds[0] ?? "swap_main";

  lines.push("// Swap target helpers for NuiSetGroupLayout:");
  lines.push('// - "_window_" is special root group target');
  lines.push('// - NUI_SWAP_MAIN points to your first detected NuiId(NuiGroup(...)) anchor');
  lines.push("// - replace if you want a different swap slot id");
  lines.push('const string NUI_SWAP_ROOT = "_window_";');
  lines.push(`const string NUI_SWAP_MAIN = "${escapeNwString(swapMainId)}";`);
  if (uniqueSwapGroupIds.length) {
    lines.push("// Detected swap-ready group ids:");
    uniqueSwapGroupIds.forEach((id) => lines.push(`// - ${id}`));
  } else {
    lines.push("// No NuiId(NuiGroup(...)) swap anchor detected. Add one and update NUI_SWAP_MAIN.");
  }
  if (swapRouteSpecs.length) {
    lines.push("// Auto-generated swap routes:");
    swapRouteSpecs.forEach((spec) => {
      lines.push(`// - ${spec.triggerId} => ${spec.functionName}() => ${spec.swapId}`);
    });
  }
  if (encouragedRouteSpecs.length) {
    lines.push("// Auto-generated encouraged click routes:");
    [...encouragedRoutesById.entries()]
      .sort(([a], [b]) => a.localeCompare(b))
      .forEach(([nuiId, specs]) => {
        const binds = [...new Set(specs.map((spec) => spec.bindId))];
        lines.push(`// - ${nuiId} => ${binds.join(", ")}`);
      });
  }
  lines.push("");

  lines.push(`void ${project.eventScript.trim()}()`);
  lines.push("{");
  lines.push("    object oPC        = NuiGetEventPlayer();");
  lines.push("    string sEventType = NuiGetEventType();");
  lines.push("    int nToken        = NuiGetEventWindow();");
  lines.push("    string sEventElem = NuiGetEventElement();");
  lines.push("    int nArrayIndex   = NuiGetEventArrayIndex();");
  lines.push("    json jPayload     = NuiGetEventPayload();");
  lines.push("    string sWindowId  = NuiGetWindowId(oPC, nToken);");
  lines.push("");
  const eventWindowGuardIds = windowIds.length ? windowIds : [baseWindowId];
  lines.push(`    if (${windowIdConditionExpr(eventWindowGuardIds)})`);
  lines.push("    {");
  lines.push(...openBindInitLines);
  lines.push('        if (sEventType == "click")');
  lines.push("        {");
  if (swapRouteSpecs.length) {
    lines.push("            // Auto-routed swap actions from NuiSwapLayout");
    swapRouteSpecs.forEach((spec) => {
      lines.push(`            if (sEventElem == "${escapeNwString(spec.triggerId)}")`);
      lines.push("            {");
      lines.push(`                NuiSetGroupLayout(oPC, nToken, "${escapeNwString(spec.swapId)}", ${spec.functionName}());`);
      lines.push("                return;");
      lines.push("            }");
    });
  }
  if (routedNuiIds.length) {
    lines.push("            // Routed by NuiId / NuiGetEventElement()");
    routedNuiIds.forEach((id) => {
      const encouragedSpecs = encouragedRoutesById.get(id) ?? [];
      lines.push(`            if (sEventElem == "${escapeNwString(id)}")`);
      lines.push("            {");
      if (encouragedSpecs.length) {
        lines.push("                // Auto-generated NuiEncouraged bind sync.");
        encouragedSpecs.forEach((spec, specIndex) => {
          if (spec.insideListTemplate) {
            const ordinal = specIndex + 1;
            const { lines: rowCountLines, rowCountVarName } = buildEncouragedRowCountResolveLines(spec, ordinal, "                ");
            lines.push(...rowCountLines);
            const rowBindKey = encouragedRowBindKey(spec.bindId);
            lines.push(
              `                NuiLib_EncouragedToggleRow(oPC, nToken, nArrayIndex, ${rowCountVarName}, "${escapeNwString(spec.bindId)}", "${escapeNwString(rowBindKey)}");`,
            );
          } else {
            const encVar = `jEncCurrent${specIndex + 1}`;
            const boolVar = `bEncCurrent${specIndex + 1}`;
            lines.push(`                json ${encVar} = NuiLib_GetBindOrDefault(oPC, nToken, "${escapeNwString(spec.bindId)}", JsonBool(FALSE));`);
            lines.push(`                int ${boolVar} = JsonGetInt(${encVar});`);
            lines.push(`                NuiLib_SetBindSafe(oPC, nToken, "${escapeNwString(spec.bindId)}", JsonBool(!${boolVar}));`);
          }
        });
        lines.push(`                // TODO: handle ${id} (optional extra click logic)`);
      } else {
        lines.push(`                // TODO: handle ${id}`);
      }
      lines.push("                return;");
      lines.push("            }");
    });
    lines.push("            // TODO: fallback click handler");
  } else {
    lines.push("            // TODO: handle clicks (add NuiId(...) on interactive widgets to route by sEventElem)");
  }
  lines.push("        }");
  lines.push("");
  lines.push('        if (sEventType == "mousedown" || sEventType == "mouseup" || sEventType == "mousescroll")');
  lines.push("        {");
  lines.push("            // TODO: handle mouse-state interactions on host widgets (eg. NuiDrawList overlays).");
  lines.push("            // nArrayIndex + jPayload are available for richer routing.");
  lines.push("        }");
  lines.push("");
  lines.push('        if (sEventType == "watch")');
  lines.push("        {");
  lines.push("            // For watch events, sEventElem is bind key.");
  lines.push("            json jWatchedValue = NuiGetBind(oPC, nToken, sEventElem);");
  lines.push("            // WARNING: writing the same watched key here can recurse.");
  lines.push("            // Use a lock guard if you write binds in watch handlers:");
  lines.push('            // if (GetLocalInt(oPC, "NUI_WATCH_LOCK") == TRUE) return;');
  lines.push('            // SetLocalInt(oPC, "NUI_WATCH_LOCK", TRUE);');
  lines.push('            // NuiSetBind(oPC, nToken, "other_bind", JsonInt(1));');
  lines.push('            // DeleteLocalInt(oPC, "NUI_WATCH_LOCK");');
  lines.push("            // TODO: handle watch routes.");
  lines.push("            return;");
  lines.push("        }");
  lines.push("    }");
  lines.push("}");
  lines.push("");
  lines.push("void main()");
  lines.push("{");
  lines.push(`    ${project.eventScript.trim()}();`);
  lines.push("}");
  lines.push("");

  if (uniqueIds.length) {
    lines.push("// NuiId values found in project:");
    uniqueIds.forEach((id) => lines.push(`// - ${id}`));
  }

  return lines.join("\n");
}

function toResRef(value: string, fallback: string): string {
  const normalized = value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_+|_+$/g, "");
  const safe = normalized || fallback;
  const prefixed = /^[0-9]/.test(safe) ? `n_${safe}` : safe;
  return prefixed.slice(0, 16);
}

function toResRefWithSuffix(base: string, suffix: string, fallbackBase: string): string {
  const cleanSuffix = toResRef(suffix, "x");
  const stem = toResRef(base, fallbackBase);
  const stemLimit = Math.max(1, 16 - (cleanSuffix.length + 1));
  return `${stem.slice(0, stemLimit)}_${cleanSuffix}`;
}

export function generateNwLivePreviewPack(project: NuiProjectMeta, root: NuiNode[], componentMap: Map<string, NuiComponent>): string {
  if (!root.length) {
    return "// Empty project. Add at least one NuiWindow.";
  }

  const baseResRef = toResRef(`nb_${project.name.trim()}`, "nb_nui_preview");
  const eventScriptResRef = project.eventScript.trim()
    ? toResRef(project.eventScript.trim(), "nb_nui_ev")
    : toResRefWithSuffix(baseResRef, "ev", "nb_nui");
  const coreScriptResRef = toResRefWithSuffix(baseResRef, "c", "nb_nui");
  const runnerScriptResRef = toResRefWithSuffix(baseResRef, "r", "nb_nui");
  const windowId = project.windowId.trim() || "NUI_WINDOW";
  const windowIds = buildWindowIds(windowId, root);
  const eventWindowGuardIds = windowIds.length ? windowIds : [windowId];

  const liveProject: NuiProjectMeta = {
    ...project,
    eventScript: eventScriptResRef,
  };

  const coreScript = generateNwScript(liveProject, root, componentMap);

  const eventScript = [
    `#include "${coreScriptResRef}"`,
    "",
    "void main()",
    "{",
    "    object oPC = NuiGetEventPlayer();",
    "    int nToken = NuiGetEventWindow();",
    "    if (!GetIsObjectValid(oPC) || nToken == 0) return;",
    "",
    "    string sWindowId = NuiGetWindowId(oPC, nToken);",
    `    if (!(${windowIdConditionExpr(eventWindowGuardIds)})) return;`,
    "",
    `    ${eventScriptResRef}();`,
    "}",
  ].join("\n");

  const runnerScript = [
    `#include "${coreScriptResRef}"`,
    "",
    "void NUIBuilder_OpenFor(object oPC)",
    "{",
    "    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC) || GetIsDM(oPC)) return;",
    "",
    `    int nOldToken = NuiFindWindow(oPC, "${windowId}");`,
    "    if (nOldToken != 0)",
    "    {",
    "        NuiDestroy(oPC, nOldToken);",
    "    }",
    "",
    `    Build_${liveProject.name.trim()}(oPC);`,
    "}",
    "",
    "void main()",
    "{",
    "    if (GetIsObjectValid(OBJECT_SELF) && GetIsPC(OBJECT_SELF))",
    "    {",
    "        NUIBuilder_OpenFor(OBJECT_SELF);",
    "        return;",
    "    }",
    "",
    "    object oPC = GetFirstPC();",
    "    while (GetIsObjectValid(oPC))",
    "    {",
    "        NUIBuilder_OpenFor(oPC);",
    "        oPC = GetNextPC();",
    "    }",
    "}",
  ].join("\n");

  const usage = [
    "// NWN 1:1 LIVE PREVIEW PACK",
    "//",
    "// Save each block as separate .nss script (resref <= 16 chars), compile, then run runner script.",
    "// Re-run runner script after each builder change to refresh the real in-game NUI.",
    "//",
    `// 1) ${coreScriptResRef}.nss`,
    `// 2) ${eventScriptResRef}.nss  (set as module OnNuiEvent OR keep as window override)`,
    `// 3) ${runnerScriptResRef}.nss (run via dm_runscript / item / command hook)`,
    "//",
    "// NOTE: Because this is rendered by NWN client, this is true 1:1 runtime preview.",
  ].join("\n");

  return [
    usage,
    "",
    `// ===== FILE: ${coreScriptResRef}.nss =====`,
    coreScript,
    "",
    `// ===== FILE: ${eventScriptResRef}.nss =====`,
    eventScript,
    "",
    `// ===== FILE: ${runnerScriptResRef}.nss =====`,
    runnerScript,
  ].join("\n");
}

export function generateAssetManifest(
  project: NuiProjectMeta,
  root: NuiNode[],
  assets: NuiAsset[],
  componentMap: Map<string, NuiComponent>,
): string {
  const used: string[] = [];
  root.forEach((node) => collectImageResRefs(node, componentMap, used));

  const projectName = project.name.trim();
  const stagingDir = `hak_staging/${projectName}`;
  const manifest = {
    project: projectName,
    supportedNuiImageFormats: ["jpg", "jpeg", "tga", "png", "gif", "webm", "wbm"],
    formatPriority: ["jpg", "tga", "png", "gif", "wbm"],
    unsupportedByNui: ["dds", "plt"],
    stagingDirectory: stagingDir,
    filesFromDesigner: assets.map((asset) => ({
      fileName: asset.name,
      extension: asset.ext,
      size: asset.size,
      supported: asset.supported,
    })),
    usedResRefsInLayout: [...new Set(used.filter(Boolean))],
    notes: [
      "To build final .hak use external NWN toolchain after copying files to stagingDirectory.",
      "Manifest helps keep resrefs and image files in sync.",
    ],
  };

  const psScript = `
# HAK staging helper (PowerShell)
$project = "${projectName}"
$staging = "${stagingDir}"
New-Item -ItemType Directory -Force -Path $staging | Out-Null
# Copy supported assets manually or with your own automation.
# Then run your HAK packer tool on $staging.
`.trim();

  return `${JSON.stringify(manifest, null, 2)}\n\n${psScript}`;
}
