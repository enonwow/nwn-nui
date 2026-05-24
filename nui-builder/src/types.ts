export type SlotType = "none" | "single" | "list";

export interface NuiArg {
  raw: string;
  type: string;
  name: string;
  defaultRaw: string | null;
}

export interface NuiComponent {
  name: string;
  signature: string;
  args: NuiArg[];
  slotType: SlotType;
  structuralArgIndex: number;
  category: string;
  wrapper: boolean;
  lexiconUrl: string;
  defaults: Record<string, string>;
}

export interface NuiNode {
  id: string;
  componentName: string;
  props: Record<string, string>;
  children: NuiNode[];
}

export interface NuiAsset {
  name: string;
  resref: string;
  ext: string;
  mimeType: string;
  previewUrl: string | null;
  sourceFile: File | null;
  size: number;
  supported: boolean;
}

export interface NuiProjectMeta {
  name: string;
  windowId: string;
  eventScript: string;
  mergeScripts?: boolean;
  resolutionWidth?: number;
  resolutionHeight?: number;
}
